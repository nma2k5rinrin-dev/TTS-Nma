// Voice Clone Edge Function — Fish Audio API
// Multipart POST: create a clone model from an audio sample.
// JSON POST { action: "synthesize" }: generate audio from an existing clone.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const jsonHeaders = {
  ...corsHeaders,
  "Content-Type": "application/json",
};

const DEFAULT_FISH_AUDIO_API_URL = "https://api.fish.audio";
const DEFAULT_FISH_TTS_MODEL = "s2-pro";

function json(data: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: jsonHeaders,
  });
}

function mimeTypeFor(fileName: string, fallback = "audio/wav"): string {
  const ext = fileName.split(".").pop()?.toLowerCase();
  switch (ext) {
    case "mp3":
      return "audio/mpeg";
    case "m4a":
      return "audio/mp4";
    case "flac":
      return "audio/flac";
    case "ogg":
      return "audio/ogg";
    case "webm":
      return "audio/webm";
    default:
      return fallback;
  }
}

function createServerConfigClient() {
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  return createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    serviceRoleKey || Deno.env.get("SUPABASE_ANON_KEY") || "",
  );
}

async function getVoiceCloneApiConfig() {
  const admin = createServerConfigClient();
  const { data } = await admin
    .from("api_configs")
    .select("provider,api_key,base_url,config")
    .eq("service", "voice_clone")
    .eq("is_active", true)
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  const apiConfig = data as {
    provider?: string;
    api_key?: string;
    base_url?: string;
    config?: Record<string, unknown>;
  } | null;

  return {
    provider: apiConfig?.provider || "fish_audio",
    apiKey: apiConfig?.api_key || Deno.env.get("FISH_AUDIO_API_KEY") || "",
    baseUrl: (apiConfig?.base_url || Deno.env.get("FISH_AUDIO_BASE_URL") || DEFAULT_FISH_AUDIO_API_URL).replace(/\/+$/, ""),
    model: (apiConfig?.config?.model as string | undefined) || Deno.env.get("FISH_TTS_MODEL") || DEFAULT_FISH_TTS_MODEL,
  };
}

async function getProfile(userId: string) {
  const adminClient = createServerConfigClient();
  const { data: profile } = await adminClient
    .from("profiles")
    .select("credits")
    .eq("id", userId)
    .single();

  return profile;
}

async function deductCredits(
  userId: string,
  amount: number,
  service: "tts" | "voice_clone" | "stt",
  description: string,
): Promise<number> {
  const adminClient = createServerConfigClient();
  const { data, error } = await adminClient.rpc("deduct_credits", {
    p_user_id: userId,
    p_amount: amount,
    p_service: service,
    p_description: description,
  });

  if (error) throw new Error(error.message);
  return Number(data);
}

async function createVoiceClone(req: Request, supabase: any, user: any): Promise<Response> {
  const formData = await req.formData();
  const name = formData.get("name") as string;
  const audioFile = formData.get("audio") as File;

  if (!name || !audioFile) {
    return json({ error: "Missing name or audio file" }, 400);
  }

  const cloneCost = 5000;
  const profile = await getProfile(user.id);
  if (!profile || profile.credits < cloneCost) {
    return json(
      {
        error: "Insufficient credits",
        required: cloneCost,
        balance: profile?.credits ?? 0,
      },
      402,
    );
  }

  const apiConfig = await getVoiceCloneApiConfig();
  if (!apiConfig.apiKey) {
    return json(
      { error: "Voice Clone service not configured. Set API key in Admin > Cài đặt API." },
      503,
    );
  }

  const ext = audioFile.name.split(".").pop() || "wav";
  const contentType = audioFile.type?.startsWith("audio/")
    ? audioFile.type
    : mimeTypeFor(audioFile.name);
  const samplePath = `voice-clone/${user.id}/${Date.now()}_sample.${ext}`;
  const audioBytes = new Uint8Array(await audioFile.arrayBuffer());

  const adminClient = createServerConfigClient();

  const { error: uploadError } = await adminClient.storage
    .from("audio")
    .upload(samplePath, audioBytes, { contentType });

  if (uploadError) {
    return json(
      { error: "Failed to save sample audio", details: uploadError.message },
      500,
    );
  }

  const { data: sampleUrl } = adminClient.storage.from("audio").getPublicUrl(samplePath);

  const cloneForm = new FormData();
  cloneForm.append("title", name);
  cloneForm.append("description", `Voice clone by ${user.email || user.id}`);
  cloneForm.append("visibility", "private");
  cloneForm.append("type", "tts");
  cloneForm.append("train_mode", "fast");
  cloneForm.append("enhance_audio_quality", "true");
  cloneForm.append("generate_sample", "false");
  cloneForm.append(
    "voices",
    new File([new Blob([audioBytes], { type: contentType })], audioFile.name, {
      type: contentType,
    }),
  );

  const cloneResponse = await fetch(`${apiConfig.baseUrl}/model`, {
    method: "POST",
    headers: { Authorization: `Bearer ${apiConfig.apiKey}` },
    body: cloneForm,
  });

  if (!cloneResponse.ok) {
    const errBody = await cloneResponse.text();
    console.error("Fish Audio create model error:", errBody);

    if (cloneResponse.status === 429) {
      return json(
        {
          error: "Đã đạt giới hạn free tier. Vui lòng thử lại sau.",
          details: errBody,
        },
        429,
      );
    }

    return json({ error: "Voice Clone API error", details: errBody }, 502);
  }

  const cloneResult = await cloneResponse.json();
  const cloneModelId = cloneResult._id || cloneResult.id;
  if (!cloneModelId) {
    return json({ error: "Fish Audio did not return a model id" }, 502);
  }

  const cloneState = cloneResult.state || "created";
  const status =
    cloneState === "failed" ? "failed" : cloneState === "training" ? "processing" : "ready";

  const newBalance = await deductCredits(
    user.id,
    cloneCost,
    "voice_clone",
    `Voice Clone: ${name} (Fish Audio)`,
  );

  const { error: insertError } = await supabase.from("voice_clones").insert({
    user_id: user.id,
    name,
    sample_audio_url: sampleUrl.publicUrl,
    clone_voice_id: cloneModelId,
    provider: apiConfig.provider,
    status,
    credits_used: cloneCost,
  });

  if (insertError) {
    return json(
      { error: "Failed to save voice clone", details: insertError.message },
      500,
    );
  }

  return json({
    voice_id: cloneModelId,
    name,
    status,
    message:
      status === "ready"
        ? "Giọng clone đã sẵn sàng để tạo audio thử."
        : "Giọng đang được xử lý.",
    credits_used: cloneCost,
    balance: newBalance,
  });
}

async function synthesizeClonedSpeech(
  body: Record<string, unknown>,
  supabase: any,
  user: any,
): Promise<Response> {
  const text = body.text?.toString().trim() ?? "";
  const voiceId = body.voice_id?.toString().trim() ?? "";
  const rate = Math.min(2, Math.max(0.5, Number(body.rate ?? 1)));

  if (!text || !voiceId) {
    return json({ error: "Missing text or voice_id" }, 400);
  }

  const { data: clone } = await supabase
    .from("voice_clones")
    .select("name, clone_voice_id, status")
    .eq("clone_voice_id", voiceId)
    .single();

  if (!clone) {
    return json({ error: "Voice clone not found" }, 404);
  }

  if (clone.status === "failed") {
    return json({ error: "Voice clone failed and cannot be used" }, 400);
  }

  const charCount = text.length;
  const creditCost = Math.ceil(charCount / 100) * 5;
  const profile = await getProfile(user.id);
  if (!profile || profile.credits < creditCost) {
    return json(
      {
        error: "Insufficient credits",
        required: creditCost,
        balance: profile?.credits ?? 0,
      },
      402,
    );
  }

  const apiConfig = await getVoiceCloneApiConfig();
  if (!apiConfig.apiKey) {
    return json(
      { error: "Voice Clone service not configured. Set API key in Admin > Cài đặt API." },
      503,
    );
  }

  const ttsResponse = await fetch(`${apiConfig.baseUrl}/v1/tts`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiConfig.apiKey}`,
      "Content-Type": "application/json",
      model: apiConfig.model,
    },
    body: JSON.stringify({
      text,
      reference_id: voiceId,
      format: "mp3",
      sample_rate: 44100,
      mp3_bitrate: 128,
      normalize: true,
      latency: "normal",
      prosody: {
        speed: rate,
        volume: 0,
        normalize_loudness: true,
      },
    }),
  });

  if (!ttsResponse.ok) {
    const errBody = await ttsResponse.text();
    console.error("Fish Audio TTS error:", errBody);

    if (ttsResponse.status === 429) {
      return json(
        {
          error: "Đã đạt giới hạn free tier. Vui lòng thử lại sau.",
          details: errBody,
        },
        429,
      );
    }

    return json({ error: "Voice Clone TTS API error", details: errBody }, 502);
  }

  const audioBytes = new Uint8Array(await ttsResponse.arrayBuffer());
  const fileName = `voice-clone/${user.id}/${Date.now()}_generated.mp3`;
  
  const adminClient = createServerConfigClient();

  const { error: uploadError } = await adminClient.storage
    .from("audio")
    .upload(fileName, audioBytes, { contentType: "audio/mpeg" });

  if (uploadError) {
    return json(
      { error: "Failed to save generated audio", details: uploadError.message },
      500,
    );
  }

  const { data: urlData } = adminClient.storage.from("audio").getPublicUrl(fileName);
  const newBalance = await deductCredits(
    user.id,
    creditCost,
    "voice_clone",
    `Voice Clone TTS: ${charCount} ký tự`,
  );

  await supabase.from("tts_history").insert({
    user_id: user.id,
    text_input: text,
    char_count: charCount,
    voice_id: voiceId,
    voice_name: clone.name,
    rate,
    pitch: 0,
    audio_url: urlData.publicUrl,
    credits_used: creditCost,
  });

  return json({
    audio_url: urlData.publicUrl,
    credits_used: creditCost,
    balance: newBalance,
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } },
    );

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return json({ error: "Unauthorized" }, 401);
    }

    const contentType = req.headers.get("Content-Type") ?? "";
    if (contentType.includes("application/json")) {
      const body = await req.json();
      if (body.action === "synthesize") {
        return await synthesizeClonedSpeech(body, supabase, user);
      }
      return json({ error: "Unsupported action" }, 400);
    }

    return await createVoiceClone(req, supabase, user);
  } catch (err) {
    return json({ error: err instanceof Error ? err.message : String(err) }, 500);
  }
});
