// TTS Generate Edge Function — Microsoft Edge TTS (FREE)
// Deploy: supabase functions deploy tts-generate
// Uses Microsoft Edge Read Aloud WebSocket protocol — no API key needed

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const DEFAULT_EDGE_TTS_TOKEN = "6A5AA1D4EAFF4E9FB37E23D68491D6F4";
const DEFAULT_EDGE_TTS_BASE_URL = "https://speech.platform.bing.com";
const DEFAULT_EDGE_TTS_OUTPUT_FORMAT = "audio-24khz-48kbitrate-mono-mp3";
const VOICE_LIST_URL = `${DEFAULT_EDGE_TTS_BASE_URL}/consumer/speech/synthesize/readaloud/voices/list?trustedclienttoken=${DEFAULT_EDGE_TTS_TOKEN}`;

type TtsRuntimeConfig = {
  wssUrl: string;
  outputFormat: string;
  elevenLabsApiKey?: string;
  elevenLabsBaseUrl: string;
  elevenLabsModel: string;
  elevenLabsOutputFormat: string;
};

type SynthesisResult = {
  audioBytes: Uint8Array;
  provider: string;
};

function generateRequestId(): string {
  return crypto.randomUUID().replace(/-/g, "");
}

function withConnectionId(wssUrl: string, connectionId: string): string {
  const url = new URL(wssUrl);
  url.searchParams.set("ConnectionId", connectionId);
  return url.toString();
}

function createServerConfigClient() {
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  return createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    serviceRoleKey || Deno.env.get("SUPABASE_ANON_KEY") || "",
  );
}

function resolveEdgeWssUrl(baseUrl: string, token: string): string {
  const trimmed = baseUrl.trim().replace(/\/+$/, "");
  if (trimmed.startsWith("wss://")) {
    return trimmed.includes("TrustedClientToken")
      ? trimmed
      : `${trimmed}?TrustedClientToken=${token}`;
  }

  const wsBase = (trimmed || DEFAULT_EDGE_TTS_BASE_URL).replace(/^http/, "ws");
  return `${wsBase}/consumer/speech/synthesize/readaloud/edge/v1?TrustedClientToken=${token}`;
}

async function getTtsRuntimeConfig(): Promise<TtsRuntimeConfig> {
  const admin = createServerConfigClient();
  const { data } = await admin
    .from("api_configs")
    .select("provider,api_key,base_url,config")
    .eq("service", "tts")
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

  const provider = apiConfig?.provider || "edge_tts";
  const token =
    provider === "edge_tts"
      ? apiConfig?.api_key || Deno.env.get("EDGE_TTS_TOKEN") || DEFAULT_EDGE_TTS_TOKEN
      : Deno.env.get("EDGE_TTS_TOKEN") || DEFAULT_EDGE_TTS_TOKEN;
  const baseUrl =
    provider === "edge_tts"
      ? apiConfig?.base_url || Deno.env.get("EDGE_TTS_BASE_URL") || DEFAULT_EDGE_TTS_BASE_URL
      : Deno.env.get("EDGE_TTS_BASE_URL") || DEFAULT_EDGE_TTS_BASE_URL;
  const outputFormat =
    (provider === "edge_tts" ? (apiConfig?.config?.model as string | undefined) : undefined) ||
    Deno.env.get("EDGE_TTS_OUTPUT_FORMAT") ||
    DEFAULT_EDGE_TTS_OUTPUT_FORMAT;
  const elevenLabsApiKey =
    provider === "elevenlabs" ? apiConfig?.api_key : Deno.env.get("ELEVENLABS_API_KEY") || undefined;
  const elevenLabsBaseUrl =
    (provider === "elevenlabs" ? apiConfig?.base_url : undefined) ||
    Deno.env.get("ELEVENLABS_BASE_URL") ||
    "https://api.elevenlabs.io";
  const elevenLabsModel =
    (provider === "elevenlabs" ? (apiConfig?.config?.model as string | undefined) : undefined) ||
    Deno.env.get("ELEVENLABS_MODEL") ||
    "eleven_multilingual_v2";
  const elevenLabsOutputFormat =
    (apiConfig?.config?.output_format as string | undefined) ||
    Deno.env.get("ELEVENLABS_OUTPUT_FORMAT") ||
    "mp3_44100_128";

  return {
    wssUrl: resolveEdgeWssUrl(baseUrl, token),
    outputFormat,
    elevenLabsApiKey,
    elevenLabsBaseUrl,
    elevenLabsModel,
    elevenLabsOutputFormat,
  };
}

function localeFromVoiceId(voiceId: string): string {
  const match = voiceId.match(/^([a-z]{2}-[A-Z]{2})-/);
  return match?.[1] ?? "vi-VN";
}

function buildSSML(text: string, voiceId: string, rate: number, pitch: number): string {
  // Rate: convert 0.5-2.0 to percentage like "+0%" or "-50%" or "+100%"
  const ratePercent = Math.round((rate - 1) * 100);
  const rateStr = ratePercent >= 0 ? `+${ratePercent}%` : `${ratePercent}%`;

  // Pitch: convert -1.0 to 1.0 → Hz offset like "+0Hz" or "-10Hz"
  const pitchHz = Math.round(pitch * 50);
  const pitchStr = pitchHz >= 0 ? `+${pitchHz}Hz` : `${pitchHz}Hz`;

  const locale = localeFromVoiceId(voiceId);

  return `<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='${locale}'>
    <voice name='${voiceId}'>
      <prosody rate='${rateStr}' pitch='${pitchStr}'>
        ${escapeXml(text)}
      </prosody>
    </voice>
  </speak>`;
}

function escapeXml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

function bytesToBase64(bytes: Uint8Array): string {
  let binary = "";
  const chunkSize = 0x8000;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunkSize));
  }
  return btoa(binary);
}

async function synthesize(
  text: string,
  voiceId: string,
  rate: number,
  pitch: number,
  runtimeConfig: TtsRuntimeConfig,
): Promise<Uint8Array> {
  const requestId = generateRequestId();

  return new Promise((resolve, reject) => {
    const ws = new WebSocket(withConnectionId(runtimeConfig.wssUrl, requestId));
    const audioChunks: Uint8Array[] = [];
    let resolved = false;

    const timeout = setTimeout(() => {
      if (!resolved) {
        resolved = true;
        ws.close();
        reject(new Error("TTS synthesis timeout (30s)"));
      }
    }, 30000);

    ws.onopen = () => {
      // Send config
      ws.send(`X-Timestamp:${new Date().toISOString()}\r\nContent-Type:application/json; charset=utf-8\r\nPath:speech.config\r\n\r\n{
        "context": {
          "synthesis": {
            "audio": {
              "metadataoptions": { "sentenceBoundaryEnabled": "false", "wordBoundaryEnabled": "false" },
              "outputFormat": "${runtimeConfig.outputFormat}"
            }
          }
        }
      }`);

      // Send SSML
      const ssml = buildSSML(text, voiceId, rate, pitch);
      ws.send(`X-RequestId:${requestId}\r\nX-Timestamp:${new Date().toISOString()}\r\nContent-Type:application/ssml+xml\r\nPath:ssml\r\n\r\n${ssml}`);
    };

    const pushAudioPayload = (payload: ArrayBuffer | Uint8Array) => {
      const bytes = payload instanceof Uint8Array ? payload : new Uint8Array(payload);
      if (bytes.byteLength <= 2) return;

      const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
      const headerLen = view.getInt16(0);
      const start = 2 + headerLen;
      if (start < bytes.byteLength) {
        audioChunks.push(bytes.slice(start));
      }
    };

    ws.onmessage = (event) => {
      if (typeof event.data === "string") {
        if (event.data.includes("Path:turn.end")) {
          clearTimeout(timeout);
          resolved = true;
          ws.close();
          // Combine audio chunks
          const totalLength = audioChunks.reduce((acc, chunk) => acc + chunk.length, 0);
          const result = new Uint8Array(totalLength);
          let offset = 0;
          for (const chunk of audioChunks) {
            result.set(chunk, offset);
            offset += chunk.length;
          }
          resolve(result);
        }
      } else if (event.data instanceof ArrayBuffer) {
        // Binary audio data — skip the header
        pushAudioPayload(event.data);
      } else if (event.data instanceof Uint8Array) {
        pushAudioPayload(event.data);
      } else if (event.data instanceof Blob) {
        // Handle Blob (Deno WebSocket may return Blob)
        event.data.arrayBuffer().then((buf: ArrayBuffer) => {
          pushAudioPayload(buf);
        });
      }
    };

    ws.onerror = (err) => {
      clearTimeout(timeout);
      if (!resolved) {
        resolved = true;
        reject(new Error(`Edge TTS WebSocket error: ${JSON.stringify(err)}`));
      }
    };

    ws.onclose = () => {
      clearTimeout(timeout);
      if (!resolved) {
        resolved = true;
        if (audioChunks.length > 0) {
          const totalLength = audioChunks.reduce((acc, chunk) => acc + chunk.length, 0);
          const result = new Uint8Array(totalLength);
          let offset = 0;
          for (const chunk of audioChunks) {
            result.set(chunk, offset);
            offset += chunk.length;
          }
          resolve(result);
        } else {
          reject(new Error("WebSocket closed without audio data"));
        }
      }
    };
  });
}

function languageFromVoiceId(voiceId: string): string {
  const match = voiceId.match(/^([a-z]{2})-([A-Z]{2})-/);
  if (!match) return "vi";

  const locale = `${match[1]}-${match[2]}`;
  if (locale === "zh-CN" || locale === "zh-HK" || locale === "pt-BR") {
    return locale;
  }
  return match[1];
}

function splitTextForHttpTts(text: string): string[] {
  const normalized = text.replace(/\s+/g, " ").trim();
  const chunks: string[] = [];
  let current = "";

  for (const part of normalized.split(/(?<=[.!?;:])\s+/)) {
    if (!part) continue;
    const next = `${current} ${part}`.trim();
    if (next.length <= 180) {
      current = next;
      continue;
    }
    if (current) chunks.push(current);
    if (part.length <= 180) {
      current = part;
    } else {
      for (let i = 0; i < part.length; i += 180) {
        chunks.push(part.slice(i, i + 180));
      }
      current = "";
    }
  }

  if (current) chunks.push(current);
  return chunks.length > 0 ? chunks : [normalized.slice(0, 180)];
}

function clampNumber(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function isGoogleTranslateVoice(voiceId: string): boolean {
  return voiceId.includes("GoogleTranslate");
}

function isElevenLabsVoice(voiceId: string): boolean {
  return voiceId.startsWith("elevenlabs:");
}

function stripVoiceProviderPrefix(voiceId: string): string {
  return voiceId.replace(/^[a-z0-9_-]+:/i, "");
}

async function synthesizeGoogleTranslateTts(
  text: string,
  voiceId: string,
  rate = 1.0,
): Promise<Uint8Array> {
  const language = languageFromVoiceId(voiceId);
  const ttsSpeed = clampNumber(rate, 0.5, 2.0);
  const audioChunks: Uint8Array[] = [];

  for (const chunk of splitTextForHttpTts(text)) {
    const url = new URL("https://translate.google.com/translate_tts");
    url.searchParams.set("ie", "UTF-8");
    url.searchParams.set("client", "tw-ob");
    url.searchParams.set("tl", language);
    url.searchParams.set("ttsspeed", ttsSpeed.toFixed(2));
    url.searchParams.set("q", chunk);

    const response = await fetch(url, {
      headers: {
        "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36",
        "Referer": "https://translate.google.com/",
      },
    });

    if (!response.ok) {
      throw new Error(`Google Translate TTS HTTP ${response.status}`);
    }

    audioChunks.push(new Uint8Array(await response.arrayBuffer()));
  }

  const totalLength = audioChunks.reduce((sum, chunk) => sum + chunk.length, 0);
  const result = new Uint8Array(totalLength);
  let offset = 0;
  for (const chunk of audioChunks) {
    result.set(chunk, offset);
    offset += chunk.length;
  }
  return result;
}

async function synthesizeElevenLabsTts(
  text: string,
  voiceId: string,
  rate: number,
  pitch: number,
  runtimeConfig: TtsRuntimeConfig,
): Promise<Uint8Array> {
  if (!runtimeConfig.elevenLabsApiKey) {
    throw new Error("Chưa cấu hình ElevenLabs API key trong màn sadmin Cài đặt API.");
  }

  const cleanVoiceId = stripVoiceProviderPrefix(voiceId);
  const baseUrl = runtimeConfig.elevenLabsBaseUrl.trim().replace(/\/+$/, "");
  const url = new URL(`${baseUrl}/v1/text-to-speech/${cleanVoiceId}`);
  url.searchParams.set("output_format", runtimeConfig.elevenLabsOutputFormat);

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Accept": "audio/mpeg",
      "Content-Type": "application/json",
      "xi-api-key": runtimeConfig.elevenLabsApiKey,
    },
    body: JSON.stringify({
      text,
      model_id: runtimeConfig.elevenLabsModel,
      language_code: "vi",
      voice_settings: {
        stability: 0.45,
        similarity_boost: 0.8,
        style: clampNumber(Math.abs(pitch) * 0.45, 0, 1),
        use_speaker_boost: true,
        speed: clampNumber(rate, 0.7, 1.2),
      },
    }),
  });

  if (!response.ok) {
    const details = await response.text();
    throw new Error(`ElevenLabs TTS HTTP ${response.status}: ${details}`);
  }

  return new Uint8Array(await response.arrayBuffer());
}

async function synthesizeWithFallback(
  text: string,
  voiceId: string,
  rate: number,
  pitch: number,
  runtimeConfig: TtsRuntimeConfig,
  allowFallback = false,
): Promise<SynthesisResult> {
  if (isGoogleTranslateVoice(voiceId)) {
    return {
      audioBytes: await synthesizeGoogleTranslateTts(text, voiceId, rate),
      provider: "google_translate_tts",
    };
  }

  if (isElevenLabsVoice(voiceId)) {
    return {
      audioBytes: await synthesizeElevenLabsTts(text, voiceId, rate, pitch, runtimeConfig),
      provider: "elevenlabs",
    };
  }

  try {
    return {
      audioBytes: await synthesize(text, voiceId, rate, pitch, runtimeConfig),
      provider: "edge_tts",
    };
  } catch (edgeError) {
    const message = edgeError instanceof Error ? edgeError.message : String(edgeError);
    if (!allowFallback) {
      throw new Error(
        `Không thể tạo đúng voice ${voiceId}. Edge TTS lỗi: ${message}`,
      );
    }

    console.warn("Edge TTS failed, falling back to Google Translate TTS", edgeError);
    return {
      audioBytes: await synthesizeGoogleTranslateTts(text, voiceId, rate),
      provider: "google_translate_tts",
    };
  }
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Special endpoint: list available voices
    if (req.method === "GET") {
      const voicesResp = await fetch(VOICE_LIST_URL);
      const voices = await voicesResp.json();
      return new Response(JSON.stringify(voices), {
        status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

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
    const { text, voice_id, rate, pitch, preview, allow_fallback } = await req.json();
    if (!text || !voice_id) {
      return new Response(JSON.stringify({ error: "Missing text or voice_id" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Voice preview is intentionally free: no storage write, no history, no credit deduction.
    if (preview === true) {
      const previewText = String(text).slice(0, 180);
      const ttsConfig = await getTtsRuntimeConfig();
      const synthesis = await synthesizeWithFallback(
        previewText,
        voice_id,
        rate ?? 1.0,
        pitch ?? 0.0,
        ttsConfig,
        allow_fallback !== false,
      );

      return new Response(JSON.stringify({
        audio_base64: bytesToBase64(synthesis.audioBytes),
        mime_type: "audio/mpeg",
        provider: synthesis.provider,
      }), {
        status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Use admin client to bypass any RLS issues and prevent user manipulation of credits
    const adminClient = createServerConfigClient();

    // Get user credits
    const { data: profile, error: profileErr } = await adminClient
      .from("profiles")
      .select("credits")
      .eq("id", user.id)
      .single();

    // Calculate cost (1 xu per 100 chars)
    const charCount = text.length;
    const creditCost = Math.ceil(charCount / 100) * 1;

    if (profileErr || !profile || profile.credits < creditCost) {
      return new Response(JSON.stringify({
        error: "Insufficient credits or profile error",
        required: creditCost,
        balance: profile?.credits ?? 0,
        debug_err: profileErr?.message
      }), {
        status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Synthesize with runtime config from sadmin settings, with Edge TTS fallback.
    const ttsConfig = await getTtsRuntimeConfig();
    const synthesis = await synthesizeWithFallback(text, voice_id, rate ?? 1.0, pitch ?? 0.0, ttsConfig);

    // Upload to Supabase Storage
    const fileName = `tts/${user.id}/${Date.now()}.mp3`;
    const { error: uploadError } = await adminClient.storage
      .from("audio")
      .upload(fileName, synthesis.audioBytes, { contentType: "audio/mpeg" });

    if (uploadError) {
      return new Response(JSON.stringify({ error: "Failed to save audio", details: uploadError.message }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get public URL
    const { data: urlData } = adminClient.storage.from("audio").getPublicUrl(fileName);

    // Deduct credits
    const newBalance = profile.credits - creditCost;
    await adminClient.from("profiles").update({ credits: newBalance }).eq("id", user.id);

    // Log transaction
    await supabase.from("credit_transactions").insert({
      user_id: user.id,
      type: "usage",
      amount: -creditCost,
      balance_after: newBalance,
      service: "tts",
      metadata: { provider: synthesis.provider },
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
      voice_name: synthesis.provider,
    });

    return new Response(JSON.stringify({
      audio_url: urlData.publicUrl,
      credits_used: creditCost,
      balance: newBalance,
      provider: synthesis.provider,
    }), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
