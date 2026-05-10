// STT Transcribe Edge Function
// Deploy: supabase functions deploy stt-transcribe
// Proxies STT requests to OpenAI Whisper API

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
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

    // Parse form data
    const formData = await req.formData();
    const audioFile = formData.get("audio") as File;
    const language = (formData.get("language") as string) || "vi";

    if (!audioFile) {
      return new Response(JSON.stringify({ error: "Missing audio file" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Estimate duration (rough: file size / bitrate)
    const fileSizeBytes = audioFile.size;
    const estimatedMinutes = Math.max(1, Math.ceil(fileSizeBytes / (128 * 1024 / 8) / 60));

    // Check credits (50 xu per minute)
    const creditCost = estimatedMinutes * 50;
    const { data: profile } = await supabase
      .from("profiles").select("credits").eq("id", user.id).single();

    if (!profile || profile.credits < creditCost) {
      return new Response(JSON.stringify({ error: "Insufficient credits", required: creditCost }), {
        status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get API config
    const { data: apiConfig } = await supabase
      .from("api_configs").select("api_key, base_url")
      .eq("service", "stt").eq("is_active", true).single();

    if (!apiConfig) {
      return new Response(JSON.stringify({ error: "STT service not configured" }), {
        status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Upload audio to storage
    const audioPath = `stt/${user.id}/${Date.now()}.${audioFile.name.split('.').pop()}`;
    const audioBytes = new Uint8Array(await audioFile.arrayBuffer());
    await supabase.storage.from("audio").upload(audioPath, audioBytes, { contentType: audioFile.type });
    const { data: audioUrl } = supabase.storage.from("audio").getPublicUrl(audioPath);

    // Call OpenAI Whisper API
    const apiKey = apiConfig.api_key;
    const baseUrl = apiConfig.base_url || "https://api.openai.com/v1";

    const whisperForm = new FormData();
    whisperForm.append("file", audioFile);
    whisperForm.append("model", "whisper-1");
    whisperForm.append("language", language);
    whisperForm.append("response_format", "verbose_json");

    const sttResponse = await fetch(`${baseUrl}/audio/transcriptions`, {
      method: "POST",
      headers: { "Authorization": `Bearer ${apiKey}` },
      body: whisperForm,
    });

    if (!sttResponse.ok) {
      const errBody = await sttResponse.text();
      return new Response(JSON.stringify({ error: "STT API error", details: errBody }), {
        status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const sttResult = await sttResponse.json();
    const transcribedText = sttResult.text;
    const actualDuration = Math.ceil((sttResult.duration || estimatedMinutes * 60) / 60);

    // Recalculate actual cost
    const actualCost = actualDuration * 50;
    const finalCost = Math.min(creditCost, actualCost);

    // Deduct credits
    const newBalance = profile.credits - finalCost;
    await supabase.from("profiles").update({ credits: newBalance }).eq("id", user.id);

    // Log transaction
    await supabase.from("credit_transactions").insert({
      user_id: user.id, type: "usage", amount: -finalCost,
      balance_after: newBalance, service: "stt",
      description: `STT: ${actualDuration} phút`,
    });

    // Log STT history
    await supabase.from("stt_history").insert({
      user_id: user.id, audio_url: audioUrl.publicUrl,
      duration_seconds: actualDuration * 60,
      transcribed_text: transcribedText,
      language: language, credits_used: finalCost, status: "completed",
    });

    return new Response(JSON.stringify({
      text: transcribedText,
      duration_minutes: actualDuration,
      credits_used: finalCost,
      balance: newBalance,
      segments: sttResult.segments || [],
    }), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
