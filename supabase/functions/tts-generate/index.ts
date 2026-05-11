// TTS Generate Edge Function — Microsoft Edge TTS (FREE)
// Deploy: supabase functions deploy tts-generate
// Uses Microsoft Edge Read Aloud WebSocket protocol — no API key needed

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Microsoft Edge TTS constants
const TRUSTED_CLIENT_TOKEN = "6A5AA1D4EAFF4E9FB37E23D68491D6F4";
const WSS_URL = `wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1?TrustedClientToken=${TRUSTED_CLIENT_TOKEN}`;
const VOICE_LIST_URL = `https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/voices/list?trustedclienttoken=${TRUSTED_CLIENT_TOKEN}`;

function generateRequestId(): string {
  return crypto.randomUUID().replace(/-/g, "");
}

function buildSSML(text: string, voiceId: string, rate: number, pitch: number): string {
  // Rate: convert 0.5-2.0 to percentage like "+0%" or "-50%" or "+100%"
  const ratePercent = Math.round((rate - 1) * 100);
  const rateStr = ratePercent >= 0 ? `+${ratePercent}%` : `${ratePercent}%`;

  // Pitch: convert -1.0 to 1.0 → Hz offset like "+0Hz" or "-10Hz"
  const pitchHz = Math.round(pitch * 50);
  const pitchStr = pitchHz >= 0 ? `+${pitchHz}Hz` : `${pitchHz}Hz`;

  return `<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'>
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

async function synthesize(text: string, voiceId: string, rate: number, pitch: number): Promise<Uint8Array> {
  const requestId = generateRequestId();

  return new Promise((resolve, reject) => {
    const ws = new WebSocket(WSS_URL);
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
      ws.send(`Content-Type:application/json; charset=utf-8\r\nPath:speech.config\r\n\r\n{
        "context": {
          "synthesis": {
            "audio": {
              "metadataoptions": { "sentenceBoundaryEnabled": "false", "wordBoundaryEnabled": "false" },
              "outputFormat": "audio-24khz-48kbitrate-mono-mp3"
            }
          }
        }
      }`);

      // Send SSML
      const ssml = buildSSML(text, voiceId, rate, pitch);
      ws.send(`X-RequestId:${requestId}\r\nContent-Type:application/ssml+xml\r\nPath:ssml\r\n\r\n${ssml}`);
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
        const view = new DataView(event.data);
        const headerLen = view.getInt16(0);
        const audioData = new Uint8Array(event.data, 2 + headerLen);
        audioChunks.push(audioData);
      } else if (event.data instanceof Blob) {
        // Handle Blob (Deno WebSocket may return Blob)
        event.data.arrayBuffer().then((buf: ArrayBuffer) => {
          const view = new DataView(buf);
          const headerLen = view.getInt16(0);
          const audioData = new Uint8Array(buf, 2 + headerLen);
          audioChunks.push(audioData);
        });
      }
    };

    ws.onerror = (err) => {
      clearTimeout(timeout);
      if (!resolved) {
        resolved = true;
        reject(new Error(`WebSocket error: ${err}`));
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

    // Calculate cost (1 xu per 100 chars)
    const charCount = text.length;
    const creditCost = Math.ceil(charCount / 100) * 1;

    if (!profile || profile.credits < creditCost) {
      return new Response(JSON.stringify({ error: "Insufficient credits", required: creditCost, balance: profile?.credits ?? 0 }), {
        status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Synthesize with Edge TTS (FREE — no API key needed!)
    const audioBytes = await synthesize(text, voice_id, rate ?? 1.0, pitch ?? 0.0);

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
