-- Add 10-session package for client 송고객
INSERT INTO session_packages (
  trainer_id,
  client_id,
  package_name,
  total_sessions,
  sessions_used,
  is_active
) VALUES (
  '9f6c6701-059d-45cc-9ee8-9e6c9ec4b62f',  -- trainer: 송준형
  'e83706a3-6b56-4956-874a-b72c3f0009de',  -- client: 송고객
  '10회 PT 패키지',
  10,
  0,
  true
);
