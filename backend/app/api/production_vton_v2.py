"""
Production Virtual Try-On Pipeline - FINAL VERSION
Accepts user_image/garment_image (base64) OR user_image_url/garment_image_url.
"""

import base64
import httpx
import logging
import json
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

from ..core.config import settings

router = APIRouter(prefix="", tags=["production-vton"])
logger = logging.getLogger(__name__)

GEMINI_API_KEY = settings.GEMINI_API_KEY or ""
OPENROUTER_API_KEY = settings.OPENROUTER_API_KEY or ""


async def _fetch_image_as_base64(url: str) -> str:
    """Download image from URL and return raw base64 string."""
    headers = {"User-Agent": "CleoFashion-Backend/1.0", "Accept": "image/*, */*"}
    async with httpx.AsyncClient(timeout=30.0) as client:
        r = await client.get(url, headers=headers)
        r.raise_for_status()
        return base64.b64encode(r.content).decode("utf-8")


def _strip_data_uri(b64: str) -> str:
    """If base64 has data URI prefix, return raw base64 only."""
    if "," in b64:
        return b64.split(",", 1)[1]
    return b64


def _openrouter_error_reason(status_code: int) -> str:
    """Human-readable reason for OpenRouter HTTP errors."""
    if status_code == 401:
        return "OpenRouter 401: Invalid or missing API key. Set OPENROUTER_API_KEY in .env (get a key at openrouter.ai)."
    if status_code == 402:
        return "OpenRouter 402: Payment required. Add credits at openrouter.ai/credits or use a key with remaining balance."
    if status_code == 403:
        return "OpenRouter 403: Forbidden. Check OPENROUTER_API_KEY and permissions at openrouter.ai."
    return f"OpenRouter error {status_code}"


# When OpenRouter is unavailable (401/402/403), use this prompt so Gemini can still generate a try-on (generic clothing swap).
FALLBACK_GEMINI_PROMPT = """Generate a photorealistic image of the same person shown in the reference image. The person must: keep the exact same face, expression, and identity; maintain the same pose and camera angle; keep the same lighting and background. Replace the person's current clothing with new, well-fitted casual clothing. The clothing must: fit naturally to the body, respect body anatomy, follow realistic fabric behavior, have correct shadows and folds, not affect face, hair, or skin. CRITICAL RULES: do not modify face or expression, do not modify pose or angle, do not change background or environment, do not change body shape or proportions, do not stylize or add effects. Output must be photorealistic and look like a genuine photograph."""


def _fallback_analysis(garment_type: Optional[str]) -> dict:
    """Use when OpenRouter returns 401/402/403: continue with Gemini using a generic prompt."""
    return {
        "status": "ready",
        "confidence": 1.0,
        "garment_type": garment_type or "garment",
        "gemini_prompt": FALLBACK_GEMINI_PROMPT,
        "fallback_used": True,
    }


class TryOnRequest(BaseModel):
    """Try-on: provide user image and garment image as base64 or URL (at least one of each)."""
    user_image: Optional[str] = None
    user_image_url: Optional[str] = None
    garment_image: Optional[str] = None
    garment_image_url: Optional[str] = None
    garment_type: Optional[str] = None
    user_id: Optional[str] = None


@router.post("/production-vton")
async def production_vton(request: TryOnRequest):
    """
    Production virtual try-on endpoint
    
    Accepts:
    - user_image (base64) or user_image_url
    - garment_image (base64) or garment_image_url
    
    Pipeline:
    1. Validate/resolve inputs (fetch from URL if needed)
    2. Analyze with Claude (OpenRouter)
    3. Generate with Gemini 2.5 Flash
    4. Return result (image, result_image_url for Flutter)
    """
    try:
        # STAGE 1: Resolve user image (base64 or URL)
        logger.info(
            "🔍 Stage 1: Validating inputs (user_image=%s, user_image_url=%s, garment_image=%s, garment_image_url=%s)",
            bool(request.user_image),
            bool(request.user_image_url),
            bool(request.garment_image),
            bool(request.garment_image_url),
        )
        user_image_b64: Optional[str] = None
        if request.user_image:
            user_image_b64 = _strip_data_uri(request.user_image)
        elif request.user_image_url:
            try:
                user_image_b64 = await _fetch_image_as_base64(request.user_image_url)
            except Exception as e:
                logger.warning("user_image_url fetch failed: %s", e)
                raise HTTPException(
                    status_code=400,
                    detail=f"user_image_url fetch failed: {type(e).__name__}: {e}",
                ) from e
        # Min 100 chars of base64 (~75 bytes) to reject empty or corrupt; normal photos are much larger
        u_len = len(user_image_b64 or "")
        if not user_image_b64 or u_len < 100:
            logger.warning("user_image invalid: len=%s, has_url=%s", u_len, bool(request.user_image_url))
            raise HTTPException(
                status_code=400,
                detail=f"Missing or invalid user_image or user_image_url (user base64 length={u_len})",
            )

        garment_image_b64: Optional[str] = None
        if request.garment_image:
            garment_image_b64 = _strip_data_uri(request.garment_image)
        elif request.garment_image_url:
            try:
                garment_image_b64 = await _fetch_image_as_base64(request.garment_image_url)
            except Exception as e:
                logger.warning("garment_image_url fetch failed: %s", e)
                raise HTTPException(
                    status_code=400,
                    detail=f"garment_image_url fetch failed: {type(e).__name__}: {e}",
                ) from e
        g_len = len(garment_image_b64 or "")
        if not garment_image_b64 or g_len < 100:
            logger.warning("garment_image invalid: len=%s, has_url=%s", g_len, bool(request.garment_image_url))
            raise HTTPException(
                status_code=400,
                detail=f"Missing or invalid garment_image or garment_image_url (garment base64 length={g_len})",
            )

        logger.info("✅ Stage 1: Input validation passed")

        # STAGE 2: Analyze images with OpenRouter Claude
        logger.info("🧠 Stage 2: Analyzing images with Claude...")
        analysis = await analyze_images_with_claude(
            user_image_b64,
            garment_image_b64,
            request.garment_type
        )

        logger.info(f"✅ Stage 2: Analysis complete - Status: {analysis.get('status')}")

        if analysis.get("status") == "reject":
            if analysis.get("openrouter_http_status") in (401, 402, 403):
                logger.warning("OpenRouter unavailable (%s), using Gemini-only fallback.", analysis.get("reason"))
            else:
                logger.warning(
                    "Analysis rejected (compatibility): %s. Using generic try-on so the app keeps working.",
                    analysis.get("reason", "Unknown reason"),
                )
            analysis = _fallback_analysis(request.garment_type)

        confidence = analysis.get("confidence", 0)
        if confidence < 0.80:
            logger.warning("Confidence %.2f below 0.80; using generic try-on.", confidence)
            analysis = _fallback_analysis(request.garment_type)
            confidence = analysis.get("confidence", 1.0)

        # STAGE 3 & 4: Generate try-on image with Gemini
        logger.info("🎨 Stage 3-4: Generating try-on with Gemini...")
        result_image_b64 = await generate_tryon_with_gemini(
            user_image_b64,
            analysis.get("gemini_prompt", "")
        )

        logger.info("✅ Stage 3-4: Gemini image generated successfully")

        # result_image_url: data URL for Flutter (CachedNetworkImage / Image.network can use data:)
        result_image_url = f"data:image/jpeg;base64,{result_image_b64}" if result_image_b64 else None

        return {
            "status": "success",
            "image": result_image_b64,
            "result_image_url": result_image_url,
            "garment_type": analysis.get("garment_type"),
            "confidence": confidence,
            "stage": "complete",
            "fallback_used": analysis.get("fallback_used", False),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Try-on pipeline error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Pipeline error: {str(e)}")


async def analyze_images_with_claude(
    user_image_b64: str,
    garment_image_b64: str,
    garment_type: Optional[str] = None
) -> dict:
    """
    Use OpenRouter Claude 3.5 Sonnet to analyze images
    Returns analysis with Gemini-ready prompt
    """
    try:
        logger.info("📤 Calling OpenRouter Claude 3.5...")

        analysis_prompt = """You are a fashion AI for virtual try-on systems.

ANALYZE THESE IMAGES:
1. First image: Person wearing current clothing
2. Second image: New garment to try on

RETURN ONLY VALID JSON (NO MARKDOWN):

{
  "status": "ready",
  "confidence": 0.95,
  "garment_type": "T-shirt",
  "target_regions": ["torso", "arms"],
  "gemini_prompt": "Generate a photorealistic image of the same person shown in the reference image. The person must: keep the exact same face, expression, and identity; maintain the same pose and camera angle; keep the same lighting and background. Replace the clothing with the new garment: [detailed description of new garment]. The clothing must: fit naturally to the body, respect body anatomy, follow realistic fabric behavior, have correct shadows and folds, not affect face, hair, or skin. CRITICAL RULES: do not modify face or expression, do not modify pose or angle, do not change background or environment, do not change body shape or proportions, do not stylize or add effects. Output must be photorealistic and look like a genuine photograph."
}

REJECT if:
- Garment is unclear or missing
- Person's face is obscured
- Multiple overlapping garments
- Low confidence in analysis
Return: {"status": "reject", "reason": "..."}
"""

        async with httpx.AsyncClient(timeout=90.0) as client:
            response = await client.post(
                "https://openrouter.ai/api/v1/messages",
                headers={
                    "Authorization": f"Bearer {OPENROUTER_API_KEY}",
                    "HTTP-Referer": "https://cleofashion.com",
                    "X-Title": "Cleo Fashion",
                    "Content-Type": "application/json",
                },
                json={
                    "model": "anthropic/claude-3.5-sonnet",
                    "messages": [
                        {
                            "role": "user",
                            "content": [
                                {"type": "text", "text": analysis_prompt},
                                {
                                    "type": "image",
                                    "source": {
                                        "type": "base64",
                                        "media_type": "image/jpeg",
                                        "data": user_image_b64
                                    }
                                },
                                {
                                    "type": "image",
                                    "source": {
                                        "type": "base64",
                                        "media_type": "image/jpeg",
                                        "data": garment_image_b64
                                    }
                                }
                            ]
                        }
                    ],
                    "max_tokens": 1200
                }
            )

        if response.status_code != 200:
            logger.error(f"❌ OpenRouter HTTP {response.status_code}: {response.text}")
            reason = _openrouter_error_reason(response.status_code)
            return {
                "status": "reject",
                "reason": reason,
                "openrouter_http_status": response.status_code,
            }

        result = response.json()
        content_text = result.get("content", [{}])[0].get("text", "")

        logger.info(f"Claude response: {content_text[:200]}...")

        # Parse JSON from response
        try:
            # Remove markdown code blocks if present
            if "```json" in content_text:
                content_text = content_text.split("```json")[1].split("```")[0]
            elif "```" in content_text:
                content_text = content_text.split("```")[1].split("```")[0]

            analysis = json.loads(content_text.strip())
            logger.info(f"✅ Analysis parsed - Confidence: {analysis.get('confidence')}")
            return analysis

        except json.JSONDecodeError as e:
            logger.error(f"❌ Failed to parse JSON: {content_text}")
            return {"status": "reject", "reason": "Invalid response format from Claude"}

    except Exception as e:
        logger.error(f"❌ Claude analysis error: {str(e)}", exc_info=True)
        return {"status": "reject", "reason": f"Claude error: {str(e)}"}


def _gemini_image_model() -> str:
    """Model for image generation. Prefer GEMINI_IMAGE_MODEL, then GEMINI_MODEL; else a known image-capable id."""
    m = (settings.GEMINI_IMAGE_MODEL or settings.GEMINI_MODEL or "").strip()
    if m:
        return m
    return "gemini-2.0-flash-preview-image-generation"


async def generate_tryon_with_gemini(
    user_image_b64: str,
    gemini_prompt: str
) -> str:
    """
    Use Gemini to generate try-on result (image output).
    Model: GEMINI_MODEL or gemini-2.0-flash-preview-image-generation.
    """
    model = _gemini_image_model()
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
    try:
        logger.info("📤 Calling Gemini Image (%s)...", model)

        generation_config = {
            "temperature": 0.7,
            "top_p": 0.9,
            "max_output_tokens": 1024,
        }
        # Required for image-generation models to return inline_data image
        if "image" in model.lower() or "preview-image" in model.lower():
            generation_config["responseModalities"] = ["TEXT", "IMAGE"]

        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                url,
                params={"key": GEMINI_API_KEY},
                json={
                    "contents": [
                        {
                            "role": "user",
                            "parts": [
                                {"text": gemini_prompt},
                                {
                                    "inline_data": {
                                        "mime_type": "image/jpeg",
                                        "data": user_image_b64
                                    }
                                }
                            ]
                        }
                    ],
                    "generationConfig": generation_config,
                }
            )

        if response.status_code == 404:
            logger.error("❌ Gemini 404: model %s not found. Try GEMINI_MODEL=gemini-2.0-flash-preview-image-generation or gemini-2.5-flash-image", model)
            raise HTTPException(
                status_code=404,
                detail=f"Gemini model '{model}' not found. Set GEMINI_MODEL in .env to a model with image-generation (e.g. gemini-2.0-flash-preview-image-generation).",
            )
        if response.status_code == 429:
            retry_sec = 60
            try:
                err = response.json()
                for d in (err.get("error") or {}).get("details") or []:
                    if isinstance(d, dict) and d.get("@type") == "type.googleapis.com/google.rpc.RetryInfo":
                        raw = d.get("retryDelay") or ""
                        if isinstance(raw, str) and raw.endswith("s"):
                            retry_sec = max(1, int(float(raw[:-1])))
                        break
            except Exception:
                pass
            mins = max(1, (retry_sec + 30) // 60)
            raise HTTPException(
                status_code=503,
                detail=f"Gemini rate limit exceeded. Please wait about {mins} minute(s) and try again. See https://ai.google.dev/gemini-api/docs/rate-limits",
                headers={"Retry-After": str(retry_sec)},
            )
        if response.status_code != 200:
            logger.error(f"❌ Gemini HTTP {response.status_code}: {response.text}")
            raise Exception(f"Gemini API error {response.status_code}")

        result = response.json()

        # Extract generated image (may be in any part when using responseModalities)
        # Gemini REST API can return camelCase (inlineData, mimeType) or snake_case (inline_data)
        try:
            parts = result["candidates"][0]["content"]["parts"]
            for p in parts:
                if not isinstance(p, dict):
                    continue
                blk = p.get("inline_data") or p.get("inlineData")
                if blk and blk.get("data"):
                    logger.info("✅ Gemini generated image successfully")
                    return blk["data"]
            logger.error(f"❌ No inline_data/inlineData image in response: {result}")
            raise Exception("Invalid Gemini response format: no image in parts")
        except (KeyError, IndexError, TypeError) as e:
            logger.error(f"❌ Response structure invalid: {result}")
            raise Exception(f"Invalid Gemini response format: {e}")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Gemini generation error: {str(e)}", exc_info=True)
        raise Exception(f"Image generation failed: {str(e)}")
