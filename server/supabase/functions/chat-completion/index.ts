/**
 * Supabase Edge Function: Chat Completion with OpenAI
 * Uses OpenAI API for AI reasoning and conversation
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") || "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_KEY") || "";

serve(async (req) => {
  try {
    const { conversation_id, user_id, message, history } = await req.json();

    if (!OPENAI_API_KEY) {
      throw new Error("OpenAI API key not configured");
    }

    // Build conversation context from history
    const messages = [
      {
        role: "system",
        content: `You are Cleo, a professional AI fashion stylist assistant for the Cleo Fashion App. You help users with:
- Fashion advice and styling recommendations
- Outfit coordination and color matching
- Understanding their personal style preferences
- Answering questions about fashion trends, occasions, and wardrobe management
- Providing personalized fashion guidance based on their quiz results

Be friendly, knowledgeable, and concise. Always provide actionable fashion advice. If you don't know something, admit it rather than guessing.`,
      },
      ...history.map((msg: any) => ({
        role: msg.role,
        content: msg.content,
      })),
      {
        role: "user",
        content: message,
      },
    ];

    // Call OpenAI API
    const openaiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini", // Cost-effective model with good reasoning
        messages: messages,
        temperature: 0.7,
        max_tokens: 500,
      }),
    });

    if (!openaiResponse.ok) {
      const error = await openaiResponse.text();
      throw new Error(`OpenAI API error: ${error}`);
    }

    const openaiData = await openaiResponse.json();
    const aiContent = openaiData.choices[0].message.content;
    const usage = openaiData.usage;

    // Return response
    return new Response(
      JSON.stringify({
        content: aiContent,
        metadata: {
          model: openaiData.model,
          tokens_used: usage.total_tokens,
          prompt_tokens: usage.prompt_tokens,
          completion_tokens: usage.completion_tokens,
        },
      }),
      {
        headers: { "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});

