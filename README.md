# TTS Nma

Flutter app for TTS, STT, and voice cloning with Supabase Edge Functions.

## Current API bridge

- TTS: Microsoft Edge Read Aloud protocol, no API key.
- STT: Groq Whisper (`whisper-large-v3-turbo`) through `stt-transcribe`.
- Voice clone: Fish Audio model creation and cloned-voice TTS through `voice-clone`.

## Local run

```bash
flutter run -d chrome --dart-define-from-file=.env
```

`.env` must contain:

```bash
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

## Supabase setup

Apply migrations, then deploy functions:

```bash
npx supabase db push
npx supabase functions deploy tts-generate
npx supabase functions deploy stt-transcribe
npx supabase functions deploy voice-clone
```

Set backend-only secrets:

```bash
npx supabase secrets set SUPABASE_SERVICE_ROLE_KEY=...
npx supabase secrets set GROQ_API_KEY=...
npx supabase secrets set FISH_AUDIO_API_KEY=...
```

After deploy, a sadmin can override provider, API key, base URL, and model from
Admin Panel -> Cài đặt API. Edge Functions read the active row in
`api_configs` first and use the env secrets only as fallback.

The `audio` storage bucket and upload/read policies are created by
`supabase/migrations/002_audio_storage_and_voice_provider.sql`.
