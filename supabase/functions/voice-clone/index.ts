// Voice Clone Edge Function
// Deploy: supabase functions deploy voice-clone
// Proxies voice clone requests to ElevenLabs API

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

    // Parse multipart form data
    const formData = await req.formData();
    const name = formData.get("name") as string;
    const audioFile = formData.get("audio") as File;

    if (!name || !audioFile) {
      return new Response(JSON.stringify({ error: "Missing name or audio file" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Check credits (5000 xu per clone)
    const cloneCost = 5000;
    const { data: profile } = await supabase
      .from("profiles").select("credits").eq("id", user.id).single();

    if (!profile || profile.credits < cloneCost) {
      return new Response(JSON.stringify({ error: "Insufficient credits", required: cloneCost }), {
        status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get API config
    const { data: apiConfig } = await supabase
      .from("api_configs").select("api_key, base_url")
      .eq("service", "voice_clone").eq("is_active", true).single();

    if (!apiConfig) {
      return new Response(JSON.stringify({ error: "Voice Clone service not configured" }), {
        status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Upload sample to storage
    const samplePath = `voice-clone/${user.id}/${Date.now()}_sample.${audioFile.name.split('.').pop()}`;
    const audioBytes = new Uint8Array(await audioFile.arrayBuffer());
    await supabase.storage.from("audio").upload(samplePath, audioBytes, { contentType: audioFile.type });
    const { data: sampleUrl } = supabase.storage.from("audio").getPublicUrl(samplePath);

    // Call ElevenLabs Add Voice API
    const apiKey = apiConfig.api_key;
    const baseUrl = apiConfig.base_url || "https://api.elevenlabs.io/v1";

    const cloneForm = new FormData();
    cloneForm.append("name", name);
    cloneForm.append("files", audioFile);

    const cloneResponse = await fetch(`${baseUrl}/voices/add`, {
      method: "POST",
      headers: { "xi-api-key": apiKey },
      body: cloneForm,
    });

    if (!cloneResponse.ok) {
      const errBody = await cloneResponse.text();
      return new Response(JSON.stringify({ error: "Clone API error", details: errBody }), {
        status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const cloneResult = await cloneResponse.json();
    const cloneVoiceId = cloneResult.voice_id;

    // Deduct credits
    const newBalance = profile.credits - cloneCost;
    await supabase.from("profiles").update({ credits: newBalance }).eq("id", user.id);

    // Log transaction
    await supabase.from("credit_transactions").insert({
      user_id: user.id, type: "usage", amount: -cloneCost,
      balance_after: newBalance, service: "voice_clone",
      description: `Voice Clone: ${name}`,
    });

    // Save clone record
    await supabase.from("voice_clones").insert({
      user_id: user.id, name: name,
      sample_audio_url: sampleUrl.publicUrl,
      clone_voice_id: cloneVoiceId,
      status: "ready", credits_used: cloneCost,
    });

    return new Response(JSON.stringify({
      voice_id: cloneVoiceId, name: name,
      credits_used: cloneCost, balance: newBalance,
    }), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
