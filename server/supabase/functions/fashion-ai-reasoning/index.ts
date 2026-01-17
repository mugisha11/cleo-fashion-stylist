/**
 * Supabase Edge Function: Fashion AI Reasoning
 * ChatGPT-level reasoning for fashion recommendations
 * Only generates outfits when explicitly requested
 * 
 * Note: TypeScript errors in IDE are expected until Deno extension is installed.
 * These functions run correctly in Supabase Edge Functions runtime.
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") || "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_KEY") || "";

serve(async (req) => {
  try {
    const { user_id, context, intent } = await req.json();

    if (!user_id || !context || !intent) {
      throw new Error("Missing required parameters");
    }

    // Only generate outfits if explicitly requested
    if (intent.type !== "outfit_request") {
    return new Response(
      JSON.stringify({
        type: "conversation",
        content:
          "I'm here to help with your fashion needs! Ask me about outfits, styling tips, or what to wear for specific occasions.",
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
    }

    // Generate outfit recommendations
    const recommendations = await generateOutfitRecommendations(
      context,
      intent
    );

    return new Response(
      JSON.stringify({
        type: "outfit_recommendations",
        date: intent.targetDate || new Date().toISOString().split("T")[0],
        recommendations,
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    console.error("Error in fashion AI reasoning:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
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

async function generateOutfitRecommendations(
  context: any,
  intent: any
): Promise<any[]> {
  const systemPrompt = `You are a world-class AI fashion stylist with the reasoning ability of ChatGPT and the taste of a luxury fashion consultant.

CRITICAL RULES:
- Generate exactly 5 outfit recommendations
- Every outfit MUST have a try-on image (user wearing it)
- Match weather conditions
- Match calendar events
- Use only items from the user's wardrobe
- Be realistic and practical
- Explain reasoning briefly (1-2 sentences)

Respond ONLY in this JSON format:
{
  "recommendations": [
    {
      "outfit_id": "uuid",
      "title": "Outfit Name",
      "reasoning": "Brief explanation",
      "weather_match": "Weather description",
      "event_match": "Event type or null",
      "outfit_item_ids": ["item_id1", "item_id2"],
      "confidence": 0.95
    }
  ]
}`;

  const userPrompt = `Generate 5 outfit recommendations for ${intent.targetDate || "today"}.

Context:
- Weather: ${JSON.stringify(context.weather)}
- Calendar: ${JSON.stringify(context.calendar)}
- Wardrobe: ${context.wardrobe?.length || 0} items
- Try-Ons: ${context.tryOns?.length || 0} saved`;

  try {
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        temperature: 0.7,
        max_tokens: 2000,
        response_format: { type: "json_object" },
      }),
    });

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.statusText}`);
    }

    const data = await response.json();
    const content = JSON.parse(data.choices[0].message.content);
    return content.recommendations || [];
  } catch (error) {
    console.error("AI generation failed:", error);
    return generateFallbackRecommendations(context);
  }
}

function generateFallbackRecommendations(context: any): any[] {
  const wardrobe = context.wardrobe || [];
  if (wardrobe.length === 0) {
    return [];
  }

  return wardrobe.slice(0, 5).map((item: any, index: number) => ({
    outfit_id: `fallback_${Date.now()}_${index}`,
    title: `${item.category || "Outfit"} Look`,
    reasoning: "A stylish look from your wardrobe",
    weather_match: "Comfortable",
    event_match: null,
    outfit_item_ids: [item.id],
    confidence: 0.7,
  }));
}
