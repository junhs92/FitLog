-- Update 송고객 with basic profile information for AI workout generation
-- Client ID: e83706a3-6b56-4956-874a-b72c3f0009de

UPDATE accounts
SET
  date_of_birth = '1992-03-15',
  gender = 'male',
  height_cm = 175,
  weight_kg = 78,
  fitness_goals = ARRAY['hypertrophy', 'strength'],
  profile_complete = true,
  updated_at = now()
WHERE id = 'e83706a3-6b56-4956-874a-b72c3f0009de';

-- Verify the update
-- SELECT id, full_name, date_of_birth, gender, height_cm, weight_kg, fitness_goals
-- FROM accounts WHERE id = 'e83706a3-6b56-4956-874a-b72c3f0009de';
