-- Storage and voice clone compatibility fixes.

ALTER TABLE public.voice_clones
  ADD COLUMN IF NOT EXISTS provider TEXT DEFAULT 'fish_audio';

INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES (
  'audio',
  'audio',
  TRUE,
  52428800,
  ARRAY[
    'audio/mpeg',
    'audio/mp3',
    'audio/wav',
    'audio/x-wav',
    'audio/mp4',
    'audio/m4a',
    'audio/aac',
    'audio/flac',
    'audio/ogg',
    'audio/webm'
  ]
)
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Authenticated users can upload own audio'
  ) THEN
    CREATE POLICY "Authenticated users can upload own audio"
      ON storage.objects
      FOR INSERT
      TO authenticated
      WITH CHECK (
        bucket_id = 'audio'
        AND (storage.foldername(name))[1] IN ('tts', 'stt', 'voice-clone')
        AND (storage.foldername(name))[2] = auth.uid()::text
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Authenticated users can read own audio'
  ) THEN
    CREATE POLICY "Authenticated users can read own audio"
      ON storage.objects
      FOR SELECT
      TO authenticated
      USING (
        bucket_id = 'audio'
        AND (storage.foldername(name))[2] = auth.uid()::text
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Public can read generated audio'
  ) THEN
    CREATE POLICY "Public can read generated audio"
      ON storage.objects
      FOR SELECT
      TO anon
      USING (bucket_id = 'audio');
  END IF;
END $$;
