-- Create the session-reports storage bucket for shareable HTML/PDF reports
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'session-reports',
  'session-reports',
  true,
  5242880,  -- 5MB limit
  ARRAY['text/html', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Allow public read access (anyone with link can view)
CREATE POLICY "Public read access for session reports"
ON storage.objects FOR SELECT
USING (bucket_id = 'session-reports');

-- Allow service role to upload (edge functions use service role)
CREATE POLICY "Service role can upload session reports"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'session-reports');
