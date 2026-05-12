// Voice Clone Edge Function — Fish Audio API (FREE tier available)
// Deploy: supabase functions deploy voice-clone
// Uses Fish Audio's voice cloning API — free tier: 3 voice slots, 7 min generation/month
// Get free API key at https://fish.audio

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const FISH_AUDIO_API_URL = "https://api.fish.audio";

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
      return new Response(JSON.stringify({ error: "Insufficient credits", required: cloneCost, balance: profile?.credits ?? 0 }), {
        status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get Fish Audio API key from environment or api_configs table
    let fishApiKey = Deno.env.get("FISH_AUDIO_API_KEY") ?? "";

    if (!fishApiKey) {
      const { data: apiConfig } = await supabase
        .from("api_configs").select("api_key")
        .eq("service", "voice_clone").eq("is_active", true).single();

      if (apiConfig) {
        fishApiKey = apiConfig.api_key;
      }
    }

    if (!fishApiKey) {
      return new Response(JSON.stringify({ error: "Voice Clone service not configured. Set FISH_AUDIO_API_KEY secret." }), {
        status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Upload sample to Supabase storage
    const samplePath = `voice-clone/${user.id}/${Date.now()}_sample.${audioFile.name.split('.').pop()}`;
    const audioBytes = new Uint8Array(await audioFile.arrayBuffer());
    await supabase.storage.from("audio").upload(samplePath, audioBytes, { contentType: audioFile.type });
    const { data: sampleUrl } = supabase.storage.from("audio").getPublicUrl(samplePath);

    // Call Fish Audio Create Model API (voice cloning)
    const cloneForm = new FormData();
    cloneForm.append("title", name);
    cloneForm.append("description", `Voice clone by ${user.email || user.id}`);
    cloneForm.append("visibility", "private");
    cloneForm.append("type", "tts");
    cloneForm.append("train_mode", "fast");
    cloneForm.append("enhance_audio_quality", "true");

    // Re-create File from bytes (Deno FormData compatibility)
    const audioBlob = new Blob([audioBytes], { type: audioFile.type });
    cloneForm.append("voices", new File([audioBlob], audioFile.name));

    const cloneResponse = await fetch(`${FISH_AUDIO_API_URL}/model`, {
      method: "POST",
      headers: { "Authorization": `Bearer ${fishApiKey}` },
      body: cloneForm,
    });

    if (!cloneResponse.ok) {
      const errBody = await cloneResponse.text();
      console.error("Fish Audio error:", errBody);

      if (cloneResponse.status === 429) {
        return new Response(JSON.stringify({
          error: "Đã đạt giới hạn free tier. Vui lòng thử lại sau.",
          details: errBody,
        }), {
          status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ error: "Voice Clone API error", details: errBody }), {
        status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const cloneResult = await cloneResponse.json();
    const cloneModelId = cloneResult._id || cloneResult.id;

    // Deduct credits
    const newBalance = profile.credits - cloneCost;
    await supabase.from("profiles").update({ credits: newBalance }).eq("id", user.id);

    // Log transaction
    await supabase.from("credit_transactions").insert({
      user_id: user.id, type: "usage", amount: -cloneCost,
      balance_after: newBalance, service: "voice_clone",
      description: `Voice Clone: ${name} (Fish Audio)`,
    });

    // Save clone record
    await supabase.from("voice_clones").insert({
      user_id: user.id, name: name,
      sample_audio_url: sampleUrl.publicUrl,
      clone_voice_id: cloneModelId,
      provider: "fish_audio",
      status: "processing", // Fish Audio trains asynchronously
      credits_used: cloneCost,
    });

    return new Response(JSON.stringify({
      voice_id: cloneModelId,
      name: name,
      status: "processing",
      message: "Giọng đang được huấn luyện. Thường mất 1-5 phút.",
      credits_used: cloneCost,
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
