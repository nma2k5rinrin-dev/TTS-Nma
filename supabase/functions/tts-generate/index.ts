// TTS Generate Edge Function
// Deploy: supabase functions deploy tts-generate
// Proxies TTS requests to ElevenLabs API

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Verify auth
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Parse request
    const { text, voice_id, rate, pitch } = await req.json();
    if (!text || !voice_id) {
      return new Response(JSON.stringify({ error: "Missing text or voice_id" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get user credits
    const { data: profile } = await supabase
      .from("profiles")
      .select("credits")
      .eq("id", user.id)
      .single();

    // Calculate cost (1 xu per 100 chars for basic)
    const charCount = text.length;
    const creditCost = Math.ceil(charCount / 100) * 1;

    if (!profile || profile.credits < creditCost) {
      return new Response(JSON.stringify({ error: "Insufficient credits", required: creditCost, balance: profile?.credits ?? 0 }), {
        status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get API config
    const { data: apiConfig } = await supabase
      .from("api_configs")
      .select("api_key, base_url, config")
      .eq("service", "tts")
      .eq("is_active", true)
      .single();

    if (!apiConfig) {
      return new Response(JSON.stringify({ error: "TTS service not configured" }), {
        status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Call ElevenLabs TTS API
    const apiKey = apiConfig.api_key;
    const baseUrl = apiConfig.base_url || "https://api.elevenlabs.io/v1";

    const ttsResponse = await fetch(`${baseUrl}/text-to-speech/${voice_id}`, {
      method: "POST",
      headers: {
        "xi-api-key": apiKey,
        "Content-Type": "application/json",
        "Accept": "audio/mpeg",
      },
      body: JSON.stringify({
        text: text,
        model_id: "eleven_multilingual_v2",
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.75,
          speed: rate ?? 1.0,
        },
      }),
    });

    if (!ttsResponse.ok) {
      const errBody = await ttsResponse.text();
      return new Response(JSON.stringify({ error: "TTS API error", details: errBody }), {
        status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get audio buffer
    const audioBuffer = await ttsResponse.arrayBuffer();
    const audioBytes = new Uint8Array(audioBuffer);

    // Upload to Supabase Storage
    const fileName = `tts/${user.id}/${Date.now()}.mp3`;
    const { error: uploadError } = await supabase.storage
      .from("audio")
      .upload(fileName, audioBytes, { contentType: "audio/mpeg" });

    if (uploadError) {
      return new Response(JSON.stringify({ error: "Failed to save audio", details: uploadError.message }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get public URL
    const { data: urlData } = supabase.storage.from("audio").getPublicUrl(fileName);

    // Deduct credits
    const newBalance = profile.credits - creditCost;
    await supabase.from("profiles").update({ credits: newBalance }).eq("id", user.id);

    // Log transaction
    await supabase.from("credit_transactions").insert({
      user_id: user.id,
      type: "usage",
      amount: -creditCost,
      balance_after: newBalance,
      service: "tts",
      description: `TTS: ${charCount} ký tự`,
    });

    // Log TTS history
    await supabase.from("tts_history").insert({
      user_id: user.id,
      text_input: text,
      char_count: charCount,
      voice_id: voice_id,
      rate: rate ?? 1.0,
      pitch: pitch ?? 0.0,
      audio_url: urlData.publicUrl,
      credits_used: creditCost,
    });

    return new Response(JSON.stringify({
      audio_url: urlData.publicUrl,
      credits_used: creditCost,
      balance: newBalance,
    }), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
