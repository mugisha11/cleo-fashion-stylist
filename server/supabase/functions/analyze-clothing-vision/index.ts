/**
 * Supabase Edge Function: Analyze Clothing with OpenAI Vision
 * Uses GPT-4o Vision for ChatGPT-level clothing understanding
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") || "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_KEY") || "";

serve(async (req) => {
  // CORS headers
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  try {
    const { image_url, image_base64 } = await req.json();

    if (!OPENAI_API_KEY) {
      throw new Error("OpenAI API key not configured");
    }

    if (!image_url && !image_base64) {
      throw new Error("Either image_url or image_base64 must be provided");
    }

    // Prepare image for OpenAI Vision
    const imageContent: any = image_url
      ? { type: "image_url", image_url: { url: image_url } }
      : {
          type: "image_url",
          image_url: {
            url: `data:image/jpeg;base64,${image_base64}`,
          },
        };

    // Structured prompt for professional fashion analysis
    const analysisPrompt = `Analyze this clothing image as a professional fashion stylist AI.

Return a JSON object with the following structure:
{
  "category": "top|bottom|dress|outerwear|shoes|accessory",
  "subcategory": "specific type (e.g., blazer, hoodie, maxi dress, jeans, skirt)",
  "confidence": 0.0-1.0,
  "colors": [
    {"hex": "#RRGGBB", "name": "Color Name", "percentage": 0-100}
  ],
  "pattern": "solid|striped|floral|graphic|plaid|denim|leather|knit|checked",
  "patternConfidence": 0.0-1.0,
  "genderStyle": "feminine|masculine|unisex",
  "fit": "slim|loose|oversized|regular",
  "season": ["summer", "winter", "spring", "fall", "all-season"],
  "occasion": ["casual", "formal", "business", "party", "sport"],
  "fabric": "cotton|denim|leather|knit|silk|synthetic|wool",
  "bodyRegion": "upper|lower|full",
  "layeringCompatibility": true|false,
  "attributes": {
    "sleeveLength": "long|short|sleeveless",
    "hasCollar": true|false,
    "length": "short|midi|long",
    "waist": "high-waist|regular|low-waist"
  }
}

Be precise. This will be used for AI outfit generation and virtual try-on.`;

    // Call OpenAI Vision API
    const openaiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: "gpt-4o", // GPT-4o Vision for best accuracy
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text: analysisPrompt },
              imageContent,
            ],
          },
        ],
        max_tokens: 1000,
        temperature: 0.3, // Lower temperature for more consistent results
        response_format: { type: "json_object" },
      }),
    });

    if (!openaiResponse.ok) {
      const error = await openaiResponse.text();
      throw new Error(`OpenAI API error: ${openaiResponse.status} - ${error}`);
    }

    const openaiData = await openaiResponse.json();
    const content = openaiData.choices[0]?.message?.content;

    if (!content) {
      throw new Error("No content in OpenAI response");
    }

    // Parse JSON response
    let analysis;
    try {
      analysis = JSON.parse(content);
    } catch (e) {
      // If response is not valid JSON, try to extract JSON from text
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        analysis = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error("Could not parse OpenAI response as JSON");
      }
    }

    // Validate and normalize response
    const normalizedAnalysis = {
      category: analysis.category || "Other",
      subcategory: analysis.subcategory || "Unknown",
      confidence: Math.min(1.0, Math.max(0.0, analysis.confidence || 0.5)),
      colors: Array.isArray(analysis.colors) ? analysis.colors : [],
      pattern: analysis.pattern || "Solid",
      patternConfidence: Math.min(1.0, Math.max(0.0, analysis.patternConfidence || 0.5)),
      genderStyle: analysis.genderStyle || "unisex",
      fit: analysis.fit || "regular",
      season: Array.isArray(analysis.season) ? analysis.season : ["all-season"],
      occasion: Array.isArray(analysis.occasion) ? analysis.occasion : ["casual"],
      fabric: analysis.fabric || "unknown",
      bodyRegion: analysis.bodyRegion || "full",
      layeringCompatibility: analysis.layeringCompatibility !== false,
      attributes: analysis.attributes || {},
    };

    return new Response(
      JSON.stringify(normalizedAnalysis),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
});
