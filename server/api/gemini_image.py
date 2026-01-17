"""
Gemini API Integration for Image Generation and Understanding
Uses Google's Gemini API for AI-powered image generation and analysis
"""

from fastapi import APIRouter, HTTPException, UploadFile, File
from pydantic import BaseModel
from typing import Optional, List
import os
from google import genai
from google.genai import types
from PIL import Image
import io
import base64

router = APIRouter(prefix="/gemini", tags=["gemini"])

# Initialize Gemini client
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyDNR_ypy6HMhdc_Jn-EX-H4xEz4O24mnZs")
client = genai.Client(api_key=GEMINI_API_KEY)

# Request/Response models
class ImageGenerationRequest(BaseModel):
    prompt: str
    model: Optional[str] = "gemini-2.5-flash-image"

class ImageGenerationResponse(BaseModel):
    image_url: str
    image_base64: Optional[str] = None
    model: str

class ImageUnderstandingRequest(BaseModel):
    prompt: Optional[str] = "Describe this image in detail"
    image_base64: Optional[str] = None
    image_url: Optional[str] = None

class ImageUnderstandingResponse(BaseModel):
    description: str
    analysis: Optional[dict] = None

@router.post("/generate-image", response_model=ImageGenerationResponse)
async def generate_image(request: ImageGenerationRequest):
    """
    Generate an image using Gemini's image generation model
    
    Example prompt: "Create a picture of a nano banana dish in a fancy restaurant with a Gemini theme"
    """
    try:
        # Generate image using Gemini
        response = client.models.generate_content(
            model=request.model,
            contents=[request.prompt],
        )
        
        # Extract image from response
        image_data = None
        for part in response.parts:
            if part.inline_data is not None:
                image_data = part.inline_data.data
                break
        
        if image_data is None:
            raise HTTPException(
                status_code=500,
                detail="No image data returned from Gemini API"
            )
        
        # Convert to PIL Image
        image = Image.open(io.BytesIO(image_data))
        
        # Save image temporarily (in production, upload to Supabase Storage)
        # For now, return base64 encoded image
        buffered = io.BytesIO()
        image.save(buffered, format="PNG")
        image_base64 = base64.b64encode(buffered.getvalue()).decode()
        
        # In production, upload to Supabase Storage and return URL
        # For now, return base64
        image_url = f"data:image/png;base64,{image_base64}"
        
        return ImageGenerationResponse(
            image_url=image_url,
            image_base64=image_base64,
            model=request.model
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate image: {str(e)}"
        )

@router.post("/understand-image", response_model=ImageUnderstandingResponse)
async def understand_image(
    request: ImageUnderstandingRequest,
    file: Optional[UploadFile] = File(None)
):
    """
    Analyze and understand an image using Gemini's vision capabilities
    
    Can accept:
    - Uploaded file
    - Base64 encoded image (in request.image_base64)
    - Image URL (in request.image_url)
    """
    try:
        image_data = None
        
        # Get image data from different sources
        if file:
            # From uploaded file
            image_data = await file.read()
        elif request.image_base64:
            # From base64 string
            image_data = base64.b64decode(request.image_base64)
        elif request.image_url:
            # From URL - download it
            import requests
            response = requests.get(request.image_url)
            image_data = response.content
        else:
            raise HTTPException(
                status_code=400,
                detail="No image provided. Use file upload, image_base64, or image_url"
            )
        
        # Convert to PIL Image
        image = Image.open(io.BytesIO(image_data))
        
        # Prepare content for Gemini
        prompt = request.prompt or "Describe this image in detail"
        
        # Generate content with image
        response = client.models.generate_content(
            model="gemini-2.0-flash-exp",
            contents=[
                types.Part.from_bytes(
                    data=image_data,
                    mime_type="image/png"  # Adjust based on actual image type
                ),
                prompt
            ],
        )
        
        # Extract text response
        description = ""
        analysis = {}
        
        for part in response.parts:
            if part.text is not None:
                description = part.text
            elif part.inline_data is not None:
                # Additional image data if returned
                analysis["has_image_data"] = True
        
        return ImageUnderstandingResponse(
            description=description,
            analysis=analysis if analysis else None
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to analyze image: {str(e)}"
        )

@router.post("/generate-text", response_model=dict)
async def generate_text(prompt: str):
    """
    Generate text using Gemini's text generation model
    """
    try:
        response = client.models.generate_content(
            model="gemini-2.0-flash-exp",
            contents=[prompt],
        )
        
        text_response = ""
        for part in response.parts:
            if part.text is not None:
                text_response += part.text
        
        return {
            "content": text_response,
            "model": "gemini-2.0-flash-exp"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate text: {str(e)}"
        )

@router.post("/chat-with-image")
async def chat_with_image(
    prompt: str,
    image_base64: Optional[str] = None,
    file: Optional[UploadFile] = File(None)
):
    """
    Chat with Gemini using both text and image context
    """
    try:
        contents = [prompt]
        
        # Add image if provided
        if file:
            image_data = await file.read()
            contents.append(
                types.Part.from_bytes(
                    data=image_data,
                    mime_type=file.content_type or "image/png"
                )
            )
        elif image_base64:
            image_data = base64.b64decode(image_base64)
            contents.append(
                types.Part.from_bytes(
                    data=image_data,
                    mime_type="image/png"
                )
            )
        
        response = client.models.generate_content(
            model="gemini-2.0-flash-exp",
            contents=contents,
        )
        
        text_response = ""
        for part in response.parts:
            if part.text is not None:
                text_response += part.text
        
        return {
            "content": text_response,
            "model": "gemini-2.0-flash-exp"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to chat with image: {str(e)}"
        )

