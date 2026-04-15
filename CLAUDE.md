# FitLog Pro — Claude Working Context

## What This App Is

FitLog Pro is an **AI-powered personal training management platform** built for personal trainers and their clients.

The core problem it solves: personal trainers spend too much time on administrative work — writing session reports, planning next workouts, tracking client progress — when they should be focused on coaching. FitLog Pro automates the paperwork so trainers can stay on the gym floor.

**The trainer runs the session. The AI handles everything else.**

- **Before the session**: AI generates the program, selects exercises, and pre-populates targets
- **During the session**: Trainer taps to log sets; the app tracks volume, detects PRs, shows rest timers
- **After the session**: AI writes the full session report automatically

**Built by:** Jass Song  
**Language:** Korean UI, English code identifiers  
**Platform:** iOS + Android (Flutter), Supabase cloud backend  
**Scope for Claude:** `FitLog_Pro_app/` only

---

## Two Distinct User Roles

### Trainer (Primary Power User)
The trainer is the main actor. They:
- Manage a roster of clients (invite, connect, track)
- Generate AI training programs per client
- Run live sessions on the gym floor (tap-to-log)
- View each client's progress, muscle activation history, and lifestyle data
- Receive AI-written session reports they can share directly

### Client (Secondary / Passive Viewer)
The client receives and views. They:
- See their session history and AI-written reports
- Track daily lifestyle (meals, water, sleep, mood)
- View their own progress stats and charts
- Accept trainer invites via QR code or invite link
- Do NOT create sessions — that is always the trainer's action

---

## Feature Breakdown (What We Are Building)

### 1. Auth & Onboarding
- Supabase Auth with PKCE flow
- Role selection at register time: `trainer` or `client`
- After login, users are routed to their role-specific home
- Clients can accept trainer invites via deep-link (`/client/invite/:code`) or QR code scan

---

### 2. Trainer Home Dashboard (`trainer_home`)
The first screen trainers see after login.
- Summary stats: total clients, sessions this week, sessions this month
- "Today's sessions" — list of scheduled sessions for today
- "Recent clients" — quick-access cards to jump into a session
- "Client activity feed" — recent actions across all clients
- Quick action buttons: start session, add client

---

### 3. Client Management (`client_management`)
Trainers manage their client roster here.
- **Add client directly** — create a new client account linked to the trainer
- **Connect to existing user** — send a connection request by username/email
- **Invite via QR / code** — generate an invite code or QR that the client scans to link themselves
- Client detail page: profile, goals, equipment preferences, injury notes
- Session history per client
- Muscle map (heatmap) per client — shows which muscles were trained in last 7/14/30 days
- Active program display

---

### 4. Calendar & Scheduling (`calendar`)
- Monthly calendar view (table_calendar widget)
- Tap a date to see scheduled sessions for that day
- Quick-schedule bottom sheet — assign a session to a date
- Edit schedule bottom sheet — modify or cancel
- Session packages — trainers sell N-session bundles (e.g., "10 session package"); the app tracks usage and remaining count

---

### 5. Active Session Recording (`active_session`) ★ Core Feature
This is the most critical screen in the app. It runs live on the gym floor.

**Starting a session:**
- From a scheduled program (pre-loaded exercises + targets)
- "Copy previous session" — repeat last session's structure
- "Empty session" — start blank, add exercises manually

**During the session:**
- Exercise cards: one card per exercise showing name (Korean), target sets/reps/weight/RPE
- Set logging: trainer taps each row to log weight, reps, RPE (1–10), optional tags (warmup, drop set, failure), optional notes
- **PR detection**: app automatically compares each set against the client's all-time best for that exercise; shows a PR badge in real time
- **Rest timer**: countdown starts automatically after each logged set
- **Exercise history panel**: shows previous session's sets side-by-side for comparison
- **In-session muscle map**: live SVG heatmap updating as sets are logged
- **Add exercise mid-session**: opens ExercisePickerDialog with smart recommendations
- **Reorder / remove exercises** during session
- Session notes field

**Completing the session:**
- Tap "Complete Session" → shows SessionSummaryScreen
- Summary: total volume, total sets, duration, exercises done, all PRs detected
- "Generate AI Report" button → triggers AI report generation

**Data stored per session:**
- `sessions` — header record with status, trainer, client, timestamps
- `session_exercises` — one row per exercise, stores targets and AI reasoning
- `set_records` — one row per set, stores weight, reps, RPE, PR type, tags

---

### 6. Exercise Library & Picker (`exercises`)
- 236 exercises covering strength, cardio, mobility, bodyweight, isometric
- Each exercise has: Korean name, category, movement pattern, movement group, muscle group, secondary muscles, equipment, difficulty, GIF/video media
- **ExercisePickerDialog** — used when adding exercises during a session:
  - "맞춤 추천" section at top — shows top 5 AI-recommended exercises with reasons
  - Exercises grouped by movement pattern (Squat, Hinge, Horizontal Push, etc.)
  - Recommended patterns highlighted with a green badge
  - Real-time search filtering

---

### 7. AI Exercise Recommendations (`ai_exercise`)
Context-aware exercise suggestion engine running on-device (no API call).

**Inputs:**
- Client's active program (preferred movement patterns, focus areas)
- Client's fitness goals
- Recent sessions (what was trained, when)
- What's already in the current session (muscle balance)

**Scoring algorithm** (higher = better recommendation):
- Pattern order score based on client goal: +10–100 pts
- Matches program focus area (e.g., chest day → chest exercises): +25 pts
- Matches program's preferred movement patterns: +20 pts
- Compound exercise (for strength/hypertrophy goals): +15 pts
- Cardio (for weight loss goal): +20 pts
- Recently performed exercise penalty: −30 pts
- Pattern already heavily used this session: −50 pts
- Upper/lower body alternation bonus: +25 pts

**Output:** Ranked list of exercises with Korean reasoning text (e.g., "프로그램 집중 부위")

**Key files:**
- `lib/features/active_session/domain/services/exercise_recommendation_service.dart`
- `lib/features/active_session/presentation/providers/exercise_picker_provider.dart`
- `lib/shared/widgets/exercise_picker_dialog.dart`

---

### 8. AI Program Generation (`ai_workout`)
Trainers generate multi-week workout programs for clients via AI.

**Trainer inputs:**
- Training split: full body / upper-lower / push-pull-legs / custom
- Focus areas: which muscle groups to prioritize
- Preferred movement patterns
- Client's fitness goals, current level, available equipment

**Process:**
1. Trainer fills the GenerateProgramScreen form
2. App calls a Supabase Edge Function (not direct OpenAI)
3. Edge function returns a structured program: days, exercises, sets, reps, RPE targets, progression notes
4. Trainer reviews on ProgramReviewScreen
5. Trainer activates it → becomes the `active` program for that client

**When active, the program:**
- Pre-populates sessions with planned exercises and targets
- Feeds into the exercise recommendation engine
- Is displayed on the client detail page

---

### 9. AI Session Reports (`ai_report`)
After every completed session, the app generates a full written analysis.

**Content of the report:**
- Volume and intensity summary
- Muscle group balance analysis
- PR highlights
- Recovery and next-session suggestions
- Progress toward client goals
- Trainer notes section

**Shareable HTML reports:**
- Trainer taps "Share Link" on the report screen
- Edge function generates a self-contained HTML file
- Uploaded to Supabase Storage (`session-reports` bucket)
- Returns a public URL
- Native share sheet opens → trainer shares via KakaoTalk, WhatsApp, or copy link
- Report is permanently accessible at that URL, print-ready as PDF

---

### 10. Workout Templates (`workout_templates`)
Reusable session structures the trainer saves and applies.
- Create template: name, list of exercises with targets
- Edit template
- Apply template to start a session for any client
- Templates are scoped to the trainer (not shared between trainers)

---

### 11. Muscle Map (`muscle_map`)
SVG body diagram (front + back view) showing muscle activation history.
- Heatmap coloring: darker = more recently/heavily trained
- Filterable by time window: 7 days / 14 days / 30 days
- Shows per-client on the client detail page
- Also shown live inside the active session (updates as sets are logged)
- Trainer uses this to spot overuse patterns or under-trained areas

---

### 12. Client Stats & Progress (`client_sessions`, `fitlog_life`)
**Client side — what clients see:**
- Session history list with AI report cards
- Volume trend charts per exercise (fl_chart)
- Muscle group distribution over time
- Lifestyle log summaries: weekly average sleep, meals logged, water intake, mood

**Trainer side — on client detail:**
- Same stats visible to trainer
- Side-by-side lifestyle + training data for readiness assessment

---

### 13. Lifestyle Tracking (`lifestyle_log` / `fitlog_life`)
Clients log daily:
- **Meals**: description, meal type (breakfast/lunch/dinner/snack), optional photo
- **Water**: glasses or ml intake
- **Sleep**: hours slept, sleep quality rating
- **Mood**: energy level, stress level, overall mood rating
- **Body photos**: progress pictures with date stamps

This data is visible to the trainer on the client detail page to inform session planning.

---

### 14. Academy (`academy`)
YouTube-based education hub for trainers.
- Videos organized by category (anatomy, programming, technique, business)
- Category chip filter bar
- In-app YouTube player

---

### 15. Client Home (Planned — NOT YET BUILT)
`client_home` feature folder does not exist yet.
Planned to be the client's daily at-a-glance screen:
- Today's lifestyle log summary
- Trainer connection status
- Last session summary
- Upcoming scheduled sessions

---

## Current Development Focus: Building a Robust App

The priority is hardening the **core app experience** so it works end-to-end without dead ends or broken flows.

**Primary goal:** Make the live session recording flow (`active_session`) fast, reliable, and polished. This is the most-used screen in the app — the trainer uses it every single session. Every tap should feel instant, every edge case should be handled, and nothing should break mid-session.

**Known gaps:**
- `client_home` feature folder does not exist yet (client's "Today" tab is unbuilt)
- Trainer profile screen is a placeholder (logout only — no real profile management)

**Ontology work is deferred** — `claudedocs/ontology/` design docs exist for future reference but are not the current focus.

---

## Project Layout

All work happens inside `FitLog_Pro_app/`. This is the root for Claude.

```
FitLog_Pro_app/
├── lib/
│   ├── features/        ← 15 feature modules (see above)
│   ├── core/
│   │   ├── config/      ← supabase_config.dart, app_config.dart
│   │   ├── constants/   ← api_constants, app_constants
│   │   ├── error/       ← Failure class hierarchy
│   │   ├── extensions/  ← context, datetime, string helpers
│   │   ├── services/    ← rest_timer, notification, exercisedb
│   │   ├── theme/       ← app_theme, colors, typography, spacing
│   │   └── utils/       ← validators, formatters
│   ├── navigation/      ← app_router.dart — ALL routes defined here
│   ├── providers/       ← global Riverpod providers
│   └── shared/
│       ├── models/      ← cross-feature data models
│       ├── services/    ← cross-feature services
│       └── widgets/     ← exercise_picker_dialog, muscle_map_widget, etc.
├── supabase/
│   └── migrations/      ← SQL files — applied manually to Supabase cloud
└── claudedocs/          ← design docs (read before changing any feature)
```

---

## Architecture Rules (Follow Strictly)

**Per-feature folder structure:**
```
lib/features/{feature}/
  data/
    datasources/    ← Supabase queries (remote) or Drift (local)
    models/         ← JSON-serializable, extends domain Entity (Freezed)
    repositories/   ← concrete implementations
  domain/
    entities/       ← pure Dart, immutable (Freezed) — no Flutter imports
    repositories/   ← abstract interfaces only
    services/       ← business logic
  presentation/
    providers/      ← Riverpod providers
    screens/        ← full-page widgets
    widgets/        ← feature-specific UI components
```

**State management:**
- `ref.watch` in widget `build` methods
- `ref.read` in callbacks and event handlers
- `ref.invalidate` to force refresh after mutations

**Models:**
- All entities use `@freezed` — never mutate, always `.copyWith()`
- After any model change: `dart run build_runner build --delete-conflicting-outputs`

**Routing:** GoRouter — `lib/navigation/app_router.dart` is the single source of truth for all routes.

**AI calls:** Always go through Supabase Edge Functions. Never call OpenAI directly from Flutter.

**Migrations:** Write SQL in `supabase/migrations/`, apply manually via Supabase dashboard. Never `supabase db push`.

---

## Coding Conventions

- **Display text is Korean** — use `exercise.nameKo`, all button/section labels in Korean
- **No mocking** in datasources — all queries hit real Supabase
- **RLS handles security** — trainers only see their clients, clients only see their own data. Don't add redundant app-level filters.
- **Session status flow is strict**: `scheduled → active → completed`. Never skip or reverse.
- **RPE scale 1–10** on every set. Stored as `NUMERIC(3,1)` in DB.
- **PRs are auto-detected** — do not add manual PR logic in UI. The service handles it.

---

## Known Issues & Gotchas

### 1. Build Runner Fragility
Freezed / json_serializable codegen breaks frequently. Always run after editing any model:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Never commit `.g.dart` or `.freezed.dart` files with conflicts.

### 2. Pre-existing Datasource Errors — DO NOT FIX
22 `argument_type_not_assignable` errors exist in legacy files. They are not our code:
- `report_remote_datasource.dart`
- `client_remote_datasource.dart`
- `connection_request_datasource.dart`
- `lifestyle_remote_datasource.dart`
- files under `scripts/`

Do not count these in error diagnostics. Do not attempt to fix them.

### 3. Supabase RLS Silent Failures
If a Supabase query returns unexpectedly empty results, suspect RLS before the query logic. Check that `trainer_id` or `client_id` in the query matches the authenticated user's UUID.

---

## Key Database Tables

| Table | Purpose |
|-------|---------|
| `accounts` | All users — `role: trainer` or `role: client` |
| `trainer_client_relationships` | Links trainer ↔ client (`status: pending / active`) |
| `sessions` | Training sessions (`scheduled → active → completed`) |
| `session_exercises` | Exercises within a session + targets + AI reasoning |
| `set_records` | Individual sets: weight, reps, RPE, PR type, tags |
| `exercises` | 236 exercises — movement, muscle, equipment, media metadata |
| `workout_programs` | AI or manual programs — split, focus areas, movement preferences |
| `workout_days` | Days within a program |
| `program_exercises` | Exercises on each program day |
| `client_exercise_familiarity` | Per-client history per exercise (times done, best weight, RPE trend) |
| `meal_logs`, `mood_logs`, `water_logs`, `activity_logs` | Client lifestyle data |
| `body_photos` | Client progress photos |
| `invitations` | QR / code invite system |
| `session_packages` | N-session bundles sold to clients — tracks remaining count |
| `session_reports` | AI report data + `html_url` for shareable link |

**RLS is enabled on every table.**

---

## Design Docs (`claudedocs/`)

Read these before modifying any feature:

| Doc | What's in it |
|-----|-------------|
| `app-goal.md` | Core positioning and MVP scope |
| `fitlog_pro_solution_overview.md` | Full feature walkthrough + flow diagrams |
| `information_architecture.md` | Complete sitemap, screen flows, state dependency map |
| `session-flow-documentation.md` | Session DB schema + complete set-logging flow |
| `database-relationships.md` | ER diagram + FK usage examples |
| `calendar_feature_implementation.md` | Calendar + package system specifics |
| `2026-01-19_exercise_recommendation_updates.md` | Recommendation scoring algorithm details |
| `2026-01-27_shareable_html_reports.md` | HTML report generation + sharing flow |
| `ontology/` | Exercise ontology design (deferred — do not implement yet) |

---

## Dev Servers (`.claude/launch.json`)

| Server | Command | Port |
|--------|---------|------|
| Flutter Web (Chrome) | `flutter run -d chrome --web-port=3000` | 3000 |
| Flutter Debug | `flutter run` | device default |
| Flutter Release | `flutter run --release` | device default |
