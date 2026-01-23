# FitLog Pro - Development Log

프로젝트 변경 사항 및 업데이트 기록

---

## 2026-01-23

### Alternative Exercise Feature (대체 운동 기능)

#### 변경 사항
기존 난이도 피드백 버튼(힘듦, 적당함, 너무 쉬움)을 제거하고, 단일 "대체 운동" 버튼으로 대체

#### 새로운 기능
- **대체 운동 버튼**: 운동 카드에 인라인으로 표시되는 컴팩트 버튼
- **Bottom Sheet**: 대체 운동을 두 그룹으로 분류하여 표시
  - 🔧 다른 장비로: 같은 움직임 패턴, 다른 장비
  - 🔁 같은 패턴: 같은 장비, 비슷한 변형 운동

#### 수정된 파일

| 파일 | 변경 내용 |
|------|----------|
| `domain/entities/alternative_exercise.dart` | 신규 - 그룹화된 대체 운동 엔티티 |
| `data/datasources/ai_workout_remote_datasource.dart` | `getAlternativeExercises()` 메서드 추가 |
| `domain/repositories/ai_workout_repository.dart` | 인터페이스 메서드 추가 |
| `data/repositories/ai_workout_repository_impl.dart` | 리포지토리 구현 |
| `presentation/providers/ai_workout_provider.dart` | `alternativeExercisesProvider` 추가 |
| `presentation/widgets/difficulty_feedback_widget.dart` | 전체 교체 - 새 UI |
| `active_session_screen.dart` | 새 버튼 사용하도록 업데이트 |

#### 쿼리 로직
```sql
-- 장비 대체 (같은 패턴, 다른 장비)
SELECT * FROM exercises
WHERE movement_group = :orig_group
  AND movement_detail = :orig_detail
  AND equipment != :orig_equipment
  AND id != :exerciseId

-- 패턴 대체 (같은 패턴, 같은 장비, 다른 운동)
SELECT * FROM exercises
WHERE movement_group = :orig_group
  AND movement_detail = :orig_detail
  AND equipment = :orig_equipment
  AND id != :exerciseId
```

#### 장비 라벨 매핑
| Equipment | Korean |
|-----------|--------|
| dumbbell | 덤벨 |
| barbell | 바벨 |
| cable | 케이블 |
| machine | 머신 |
| bodyweight | 맨몸 |
| smith_machine | 스미스머신 |
| kettlebell | 케틀벨 |

**상세 문서**: `claudedocs/2026-01-23_alternative_exercise_feature.md`

---

## 2024-12-08

### Security: Account Creation via Database Trigger

#### 문제
- 회원가입 시 `accounts` 테이블 직접 insert → 401 오류 (RLS 정책 차단)

#### 해결 (보안 강화)
클라이언트에서 직접 테이블 접근 대신 **Database Trigger** 사용

**변경 사항:**
1. **Flutter 코드 수정** (`auth_remote_datasource.dart`)
   - `signUp()` 시 `data` 파라미터로 메타데이터 전달
   - 직접 insert 제거 → 트리거가 자동 생성

2. **Supabase Migration 필요** (수동 실행)
   ```sql
   -- 새 유저 등록 시 accounts 자동 생성
   CREATE OR REPLACE FUNCTION public.handle_new_user()
   RETURNS TRIGGER
   LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public
   AS $$
   BEGIN
     INSERT INTO public.accounts (
       user_id, email, full_name, role,
       is_active, profile_complete, created_at, updated_at
     ) VALUES (
       NEW.id, NEW.email,
       COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
       COALESCE(NEW.raw_user_meta_data->>'role', 'client'),
       true, false, NOW(), NOW()
     );
     RETURN NEW;
   END;
   $$;

   DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
   CREATE TRIGGER on_auth_user_created
     AFTER INSERT ON auth.users
     FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
   ```

**보안 이점:**
- RLS 정책 유지 (클라이언트 직접 접근 차단)
- 서버 사이드에서 계정 생성 (SECURITY DEFINER)
- 개인정보 노출 위험 최소화

---

## 🚀 Deployment Checklist

배포 전 반드시 설정해야 할 항목들

### Supabase Authentication Settings

**Dashboard → Authentication → URL Configuration:**

| Setting | Development | Production |
|---------|-------------|------------|
| Site URL | `http://localhost:3000` | `https://your-domain.com` |
| Redirect URLs | `http://localhost:3000/**` | `https://your-domain.com/**` |

**주의사항:**
- 이메일 확인 링크가 올바른 URL로 리다이렉트되도록 설정 필요
- 프로덕션에서는 HTTPS 필수
- 여러 환경(staging, production)을 사용할 경우 모든 URL 추가

### SMTP 설정 (이메일 발송)

프로덕션에서는 커스텀 SMTP 설정 권장:
- **Dashboard → Project Settings → Auth → SMTP Settings**
- 기본 Supabase SMTP: 시간당 4개 제한
- 프로덕션용: SendGrid, Mailgun, AWS SES 등 사용

### Environment Variables

프로덕션 배포 시 환경 변수 설정:
```
SUPABASE_URL=https://[project-ref].supabase.co
SUPABASE_ANON_KEY=[production-anon-key]
```

---

## 2024-12-06

### Session Setup & Configuration

#### Supabase 연동 설정
- **문제**: `Supabase.instance` 호출 시 초기화 오류 발생
- **원인**: 환경 변수(`SUPABASE_URL`, `SUPABASE_ANON_KEY`)가 전달되지 않음
- **해결**:
  - `.env` 파일 생성 (gitignore 적용됨)
  - `.vscode/launch.json` 생성하여 VS Code 실행 설정 추가

**실행 방법:**
```bash
# 터미널
flutter run -d chrome --web-port=3000 \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...

# VS Code
F5 → "FitLog Pro (Chrome)" 선택
```

#### 생성된 파일
| 파일 | 용도 |
|------|------|
| `.env` | Supabase 자격 증명 (gitignore) |
| `.env.example` | 다른 개발자용 템플릿 |
| `.vscode/launch.json` | VS Code 실행 설정 (gitignore) |

---

### Trainer Verification Code 기능 추가

#### 변경 사항
트레이너로 회원가입 시 인증 코드 필요하도록 구현

**수정된 파일:**
- `lib/core/constants/app_constants.dart`
  - `trainerVerificationCode = 'fitlogcertified'` 상수 추가

- `lib/features/auth/presentation/screens/register_screen.dart`
  - 트레이너 코드 입력 필드 추가 (트레이너 선택 시에만 표시)
  - 코드 검증 로직 추가
  - 비밀번호처럼 숨김/표시 토글 기능

**동작:**
```
Trainer 선택 → "fitlogcertified" 입력 → 회원가입 진행
Client 선택  → 코드 없이 회원가입 진행
```

---

### Documentation 추가

#### 생성된 문서
- `docs/technical/ARCHITECTURE.md` - 코드 아키텍처 가이드
  - 디렉토리 구조 설명
  - Clean Architecture 패턴
  - Riverpod 상태 관리
  - GoRouter 네비게이션
  - Supabase 연동
  - 기능 모듈 분석
  - 데이터 흐름 다이어그램
  - 새 기능 추가 방법

#### README.md 업데이트
- 실행 방법 개선 (VS Code / 터미널)
- ARCHITECTURE.md 문서 링크 추가

---

### Supabase MCP 설정

#### 문제
- Supabase MCP 연결 실패 (authentication 오류)

#### 해결
- HTTP 타입 remote MCP 설정으로 변경
- Personal Access Token (PAT) 사용

**설정 파일:** `.claude/mcp.json`
```json
"supabase": {
  "type": "http",
  "url": "https://mcp.supabase.com/mcp?project_ref=xxx&read_only=true",
  "headers": {
    "Authorization": "Bearer <PAT>"
  }
}
```

---

### UI Design Benchmark 추가

#### 생성된 문서
- `docs/design/UI_BENCHMARK.md` - UI 디자인 벤치마크 가이드
  - Nutridea 앱 기반 디자인 분석
  - 컬러 팔레트 (Bright Blue, Patterns Blue, Blue Chalk, Midnight Blue, Black, Gray)
  - 버튼 스타일 (Primary: 오렌지-옐로우 그라데이션, Secondary: 투명 pill)
  - 타이포그래피 스케일
  - 컴포넌트 스펙 (Cards, Progress Indicators, Inputs)
  - 레이아웃 패턴 및 스페이싱
  - FitLog Pro 적용 가이드

#### 주요 컬러
| Name | Hex Code | Usage |
|------|----------|-------|
| Bright Blue | `#2563EB` | Primary actions |
| Patterns Blue | `#DBEAFE` | Light backgrounds |
| Blue Chalk | `#EEF2FF` | Card backgrounds |
| Midnight Blue | `#1E3A5F` | Headers |
| Black | `#121212` | Primary text |
| Gray | `#787B7F` | Secondary text |

#### 버튼 스타일
- **Primary**: Gradient `#F59E0B` → `#FB923C`, pill shape (999px radius)
- **Secondary**: Transparent, border `#E5E7EB`, pill shape

---

### Database Schema 연동 (accounts 테이블)

#### 변경 사항
기존 `users` 테이블 대신 Supabase의 `accounts` 테이블 사용하도록 수정

**수정된 파일:**

| 파일 | 변경 내용 |
|------|----------|
| `lib/core/constants/api_constants.dart` | `usersTable` → `accountsTable` |
| `lib/features/auth/data/models/user_model.dart` | accounts 테이블 스키마에 맞게 필드 매핑 |
| `lib/features/auth/data/datasources/auth_remote_datasource.dart` | `user_id` 필드로 쿼리 변경 |

**필드 매핑:**
| App Code | accounts 테이블 |
|----------|----------------|
| `id` | `id` (uuid, PK) |
| `userId` | `user_id` (auth.users.id 참조) |
| `name` | `full_name` |
| `profilePhotoUrl` | `avatar_url` |
| `role` | `role` ('trainer', 'client', 'both') |

**accounts 테이블 구조:**
- `id` (uuid, PK, auto-generated)
- `user_id` (uuid, FK → auth.users.id)
- `email`, `full_name`, `phone`, `avatar_url`
- `role` (trainer/client/both)
- `is_active`, `profile_complete`
- `created_at`, `updated_at`, `last_login_at`

---

## Project Status

### 완료된 기능
- [x] 프로젝트 기본 구조 (Phase 0)
- [x] 인증 시스템 (로그인/회원가입)
- [x] 트레이너 인증 코드 검증
- [x] 클라이언트 관리 (Phase 1)
- [x] 트레이너 홈 대시보드 (Phase 2)
- [x] Supabase 연동 설정
- [x] UI 디자인 벤치마크 문서

### 진행 중
- [ ] Active Session 기능
- [ ] AI Workout 생성
- [ ] Lifestyle Log 기능
- [ ] AI Report 기능

### 기술 스택
- Flutter 3.16+ / Dart 3.2+
- Riverpod (상태 관리)
- GoRouter (네비게이션)
- Supabase (백엔드)
- Freezed + JSON Serializable (모델)
- dartz Either (에러 처리)

---

## Notes

### 환경 변수 주의사항
Flutter는 `.env` 파일을 자동으로 읽지 않음. 반드시 `--dart-define`으로 전달 필요:
```bash
--dart-define=SUPABASE_URL=값
--dart-define=SUPABASE_ANON_KEY=값
```

### 트레이너 인증 코드
- 코드: `fitlogcertified`
- 위치: `AppConstants.trainerVerificationCode`
- 변경 시 `app_constants.dart` 수정

---

*Last Updated: 2024-12-06*
