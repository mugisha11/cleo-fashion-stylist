/**
 * Supabase Edge Function: Daily Outfit Recommendations
 * Generates exactly 3 intelligent outfit recommendations per user per day
 * Called by Firebase Cloud Function cron scheduler
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") || "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_KEY") || "";

interface UserContext {
  user: any;
  wardrobe: any[];
  calendar: any[];
  weather: any;
  tryOns: any[];
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  try {
    const { user_id, date } = await req.json();

    if (!user_id) {
      return new Response(
        JSON.stringify({ error: "user_id is required" }),
        { 
          status: 400,
          headers: { 
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          }
        }
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const targetDate = date ? new Date(date) : new Date();
    const dateKey = targetDate.toISOString().split("T")[0];

    // STEP 1: Fetch User Context
    const context = await fetchUserContext(supabase, user_id, targetDate);

    // STEP 2: Call AI to generate recommendations
    const recommendations = await generateRecommendationsWithAI(context, targetDate);

    // Ensure exactly 3 recommendations
    if (recommendations.length !== 3) {
      console.warn(`Generated ${recommendations.length} recommendations, expected 3`);
      const fallback = generateFallbackRecommendations(context, targetDate);
      recommendations.splice(0, recommendations.length, ...fallback.slice(0, 3));
    }

    // STEP 3: Ensure try-on images exist for each recommendation
    const recommendationsWithTryOns = await ensureTryOnImages(
      supabase,
      user_id,
      recommendations,
      context
    );

    // STEP 4: Validate recommendations
    const validated = recommendationsWithTryOns.filter(rec => 
      rec.outfit_item_ids && 
      rec.outfit_item_ids.length > 0 &&
      rec.confidence >= 0 && 
      rec.confidence <= 1
    );

    if (validated.length !== 3) {
      throw new Error(`Validation failed: expected 3 valid recommendations, got ${validated.length}`);
    }

    // Return recommendations for Firebase Function to save
    return new Response(
      JSON.stringify({
        success: true,
        count: validated.length,
        recommendations: validated,
      }),
      { 
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        }
      }
    );
  } catch (error) {
    console.error("Error generating recommendations:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500, 
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        }
      }
    );
  }
});

async function fetchUserContext(
  supabase: any,
  userId: string,
  date: Date
): Promise<UserContext> {
  // Get user profile
  const { data: user } = await supabase
    .from("users")
    .select()
    .eq("id", userId)
    .single();

  // Get wardrobe items
  const { data: wardrobe } = await supabase
    .from("wardrobe_items")
    .select()
    .eq("user_id", userId);

  // Get calendar events for today and next 24h
  const startDate = date.toISOString().split("T")[0];
  const endDate = new Date(date.getTime() + 24 * 60 * 60 * 1000)
    .toISOString()
    .split("T")[0];

  const { data: calendar } = await supabase
    .from("calendar_days")
    .select()
    .eq("user_id", userId)
    .gte("date", startDate)
    .lte("date", endDate);

  // Get weather (handled by Firebase Function, placeholder here)
  const weather = {
    temperature: 20,
    condition: "clear",
    description: "Clear sky",
  };

  // Get recent try-ons (last 7 days to avoid repeats)
  const sevenDaysAgo = new Date(date);
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  const { data: tryOns } = await supabase
    .from("tryon_sessions")
    .select()
    .eq("user_id", userId)
    .gte("created_at", sevenDaysAgo.toISOString())
    .order("created_at", { ascending: false })
    .limit(20);

  return {
    user: user || {},
    wardrobe: wardrobe || [],
    calendar: calendar || [],
    weather,
    tryOns: tryOns || [],
  };
}

async function generateRecommendationsWithAI(
  context: UserContext,
  date: Date
): Promise<any[]> {
  if (!OPENAI_API_KEY) {
    // Fallback to rule-based recommendations
    return generateFallbackRecommendations(context, date);
  }

  const systemPrompt = `You are a world-class AI fashion stylist with the reasoning ability of ChatGPT and the taste of a luxury fashion consultant.

Your task: Generate exactly 3 intelligent outfit recommendations for the user.

CRITICAL RULES (NEVER BREAK):
- Generate EXACTLY 3 recommendations (no more, no less)
- Never invent clothes - use ONLY items from the user's wardrobe
- Never recommend unavailable items
- Never repeat yesterday's exact outfit
- Match weather conditions
- Match calendar events
- Be realistic and practical
- Explain reasoning briefly (1-2 lines)

HARD RULES:
❌ Never invent clothes
❌ Never recommend unavailable items
❌ Never repeat yesterday's exact outfit
❌ Never generate more than 3 outfits

SOFT RULES (PREFER):
- Balance colors
- Match weather
- Match calendar mood
- Respect user's dominant style

Context:
- Weather: ${JSON.stringify(context.weather)}
- Calendar Events: ${JSON.stringify(context.calendar)}
- Wardrobe Items: ${context.wardrobe.length} items
- Recent Try-Ons: ${context.tryOns.length} saved

Wardrobe Items Available:
${JSON.stringify(context.wardrobe.map((item: any) => ({
  id: item.id,
  category: item.category,
  colors: item.color_tags || item.extracted_colors || [],
  pattern: item.pattern || item.extracted_pattern,
})).slice(0, 100))}

Respond ONLY in this JSON format:
{
  "recommendations": [
    {
      "outfit_id": "uuid",
      "title": "Outfit Name",
      "reasoning": "Brief explanation (1-2 lines)",
      "weather_match": "Weather description",
      "event_match": "Event type or null",
      "outfit_item_ids": ["item_id1", "item_id2", "item_id3"],
      "confidence": 0.95
    }
  ]
}`;

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
          {
            role: "user",
            content: `Generate exactly 3 outfit recommendations for ${date.toISOString().split("T")[0]}. Use only items from the wardrobe provided.`,
          },
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
    const recommendations = content.recommendations || [];
    
    // Ensure exactly 3 recommendations
    if (recommendations.length > 3) {
      console.warn(`AI generated ${recommendations.length} recommendations, truncating to 3`);
      return recommendations.slice(0, 3);
    }
    
    if (recommendations.length < 3) {
      console.warn(`AI generated only ${recommendations.length} recommendations, using fallback`);
      const fallback = generateFallbackRecommendations(context, date);
      return fallback.slice(0, 3);
    }
    
    return recommendations;
  } catch (error) {
    console.error("AI generation failed, using fallback:", error);
    return generateFallbackRecommendations(context, date);
  }
}

async function ensureTryOnImages(
  supabase: any,
  userId: string,
  recommendations: any[],
  context: UserContext
): Promise<any[]> {
  const updated = [];

  for (const rec of recommendations) {
    // Check if try-on already exists for this outfit combination
    const outfitKey = rec.outfit_item_ids.sort().join(",");
    const existingTryOn = context.tryOns.find((t) =>
      t.outfit_ids?.sort().join(",") === outfitKey
    );

    if (existingTryOn) {
      rec.tryon_image_url = existingTryOn.result_image_url;
    } else {
      // Generate new try-on image (placeholder for now)
      // TODO: Integrate with actual try-on service
      rec.tryon_image_url = null;
    }

    updated.push(rec);
  }

  return updated;
}

function generateFallbackRecommendations(
  context: UserContext,
  date: Date
): any[] {
  // Rule-based fallback when AI is unavailable
  const recommendations = [];
  const wardrobe = context.wardrobe || [];
  const weather = context.weather || { temperature: 20, condition: "clear" };

  // Group wardrobe by category
  const byCategory: Record<string, any[]> = {};
  wardrobe.forEach((item) => {
    const cat = (item.category || "other").toLowerCase();
    if (!byCategory[cat]) byCategory[cat] = [];
    byCategory[cat].push(item);
  });

  // Generate exactly 3 basic recommendations
  // Group by category
  const tops = byCategory["top"] || byCategory["shirt"] || byCategory["t-shirt"] || [];
  const bottoms = byCategory["bottom"] || byCategory["pants"] || byCategory["jeans"] || [];
  const shoes = byCategory["shoes"] || byCategory["shoe"] || [];
  const outerwear = byCategory["outerwear"] || byCategory["jacket"] || [];
  
  // Recommendation 1: Top + Bottom + Shoes
  if (tops.length > 0 && bottoms.length > 0) {
    const top = tops[0];
    const bottom = bottoms[0];
    const shoe = shoes.length > 0 ? shoes[0] : null;
    
    const itemIds = [top.id, bottom.id];
    if (shoe) itemIds.push(shoe.id);
    
    recommendations.push({
      outfit_id: `fallback_${Date.now()}_1`,
      title: "Classic Casual Look",
      reasoning: `Perfect for ${weather.condition} weather. Balanced and comfortable.`,
      weather_match: weather.condition,
      event_match: null,
      outfit_item_ids: itemIds,
      confidence: 0.75,
    });
  }
  
  // Recommendation 2: Top + Bottom (different combo)
  if (tops.length > 1 && bottoms.length > 0) {
    const top = tops[1];
    const bottom = bottoms[0];
    
    recommendations.push({
      outfit_id: `fallback_${Date.now()}_2`,
      title: "Fresh Everyday Style",
      reasoning: `Great for ${weather.condition} conditions. Versatile and stylish.`,
      weather_match: weather.condition,
      event_match: null,
      outfit_item_ids: [top.id, bottom.id],
      confidence: 0.70,
    });
  }
  
  // Recommendation 3: With outerwear if available
  if (tops.length > 0 && bottoms.length > 0 && outerwear.length > 0) {
    const top = tops[0];
    const bottom = bottoms[0];
    const jacket = outerwear[0];
    
    recommendations.push({
      outfit_id: `fallback_${Date.now()}_3`,
      title: "Layered Comfort",
      reasoning: `Layered look perfect for ${weather.condition} weather.`,
      weather_match: weather.condition,
      event_match: null,
      outfit_item_ids: [top.id, bottom.id, jacket.id],
      confidence: 0.72,
    });
  } else if (tops.length > 0 && bottoms.length > 0) {
    // Fallback: third combo
    const top = tops.length > 2 ? tops[2] : tops[0];
    const bottom = bottoms.length > 1 ? bottoms[1] : bottoms[0];
    
    recommendations.push({
      outfit_id: `fallback_${Date.now()}_3`,
      title: "Versatile Outfit",
      reasoning: `Adaptable style for ${weather.condition} weather.`,
      weather_match: weather.condition,
      event_match: null,
      outfit_item_ids: [top.id, bottom.id],
      confidence: 0.68,
    });
  }
  
  // Ensure exactly 3 recommendations
  return recommendations.slice(0, 3);
}
