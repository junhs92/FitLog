# FitLog Pro - 정보 구조도, Flowchart & Critical Path

> **Version:** 1.1 | **Date:** 2026-04-15 (updated from 1.0 / 2026-02-24)
> **App:** FitLog Pro (Flutter + Supabase)
> **Architecture:** Clean Architecture + Riverpod + GoRouter

---

## Table of Contents

1. [서비스 개요 (Service Overview)](#1-서비스-개요)
2. [사용자 역할 구조 (User Role Architecture)](#2-사용자-역할-구조)
3. [정보 구조도 (Information Architecture)](#3-정보-구조도)
4. [화면 흐름도 (Screen Flowcharts)](#4-화면-흐름도)
5. [데이터 흐름도 (Data Flow Architecture)](#5-데이터-흐름도)
6. [Critical Path 분석](#6-critical-path-분석)
7. [데이터베이스 ER 구조](#7-데이터베이스-er-구조)
8. [상태 관리 의존성 맵](#8-상태-관리-의존성-맵)

---

## 1. 서비스 개요

FitLog Pro는 **퍼스널 트레이너**와 **클라이언트** 간의 운동 세션 관리를 위한 AI 기반 플랫폼이다.

```
┌─────────────────────────────────────────────────────────┐
│                    FitLog Pro                            │
│                                                         │
│  "AI-powered Personal Training Management Platform"     │
│                                                         │
│  ┌──────────────┐    관계     ┌──────────────┐          │
│  │   트레이너    │◄──────────►│   클라이언트   │          │
│  │  (Trainer)    │  1 : N     │   (Client)    │          │
│  └──────┬───────┘            └──────┬───────┘          │
│         │                           │                   │
│    ┌────┴────┐                ┌─────┴────┐              │
│    │운동 세션 │                │라이프 로그│              │
│    │AI 프로그램│                │세션 기록  │              │
│    │리포트 생성│                │통계 조회  │              │
│    │일정 관리 │                │초대 수락  │              │
│    │아카데미  │                │프로필    │              │
│    └─────────┘                └──────────┘              │
└─────────────────────────────────────────────────────────┘
```

### 핵심 기능 요약

| 도메인 | 기능 | 설명 |
|--------|------|------|
| **인증** | 회원가입/로그인 | Supabase Auth (PKCE), 역할 기반 분기 |
| **운동 세션** | 실시간 세션 기록 | 운동 추가, 세트 로깅, 휴식 타이머, RPE |
| **AI 프로그램** | 프로그램 생성 | Edge Function 기반 AI 운동 추천 |
| **운동 추천** | 컨텍스트 기반 추천 | 세션 내 실시간 운동 추천 (클라이언트 사이드) |
| **리포트** | AI 세션 리포트 | HTML 리포트 생성 및 공유 |
| **클라이언트 관리** | 초대/연결 | QR코드, 초대코드, 연결 요청 |
| **라이프 로그** | 식단/수면/기분/수분 | 클라이언트 일상 기록 |
| **근육 맵** | SVG 바디맵 | 히트맵 기반 근육 활동 시각화 |
| **캘린더** | 일정 관리 | 세션 스케줄 + 패키지 관리 |
| **아카데미** | 교육 영상 | YouTube 기반 카테고리별 영상 |
| **템플릿** | 운동 템플릿 | 재사용 가능 세션 구조 저장 |

---

## 2. 사용자 역할 구조

```
┌─────────────────────────────────────────────────────────────┐
│                    인증 시스템 (Auth)                         │
│                                                             │
│  Supabase Auth (PKCE) → accounts 테이블 → UserEntity        │
│                                                             │
│  ┌────────────────────┐      ┌────────────────────┐        │
│  │   UserRole.trainer  │      │   UserRole.client   │        │
│  │                    │      │                    │        │
│  │  권한:              │      │  권한:              │        │
│  │  - 클라이언트 관리  │      │  - 본인 데이터 조회 │        │
│  │  - 세션 생성/진행   │      │  - 라이프 로그 입력 │        │
│  │  - AI 프로그램 생성 │      │  - 세션 기록 열람   │        │
│  │  - 리포트 생성      │      │  - 리포트 열람      │        │
│  │  - 일정 관리       │      │  - 초대 수락       │        │
│  │  - 아카데미 접근    │      │  - 통계 조회       │        │
│  │  - 템플릿 관리      │      │  - 프로필 관리     │        │
│  └────────────────────┘      └────────────────────┘        │
│                                                             │
│  RLS 정책:                                                  │
│  trainer → trainer_id 기준 접근                              │
│  client  → client_id 기준 접근                               │
│  cross   → trainer_client_relationships.status = 'active'   │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. 정보 구조도

### 3.1 전체 네비게이션 구조 (Sitemap)

```
FitLog Pro App
│
├── / (SplashScreen) ─── 인증 상태 확인 → 자동 리다이렉트
│
├── /login (LoginScreen)
│   ├── /register (RegisterScreen) ← 역할 선택: trainer | client
│   └── /forgot-password (ForgotPasswordScreen) ← 비밀번호 재설정 이메일 발송
│
│
├══════════════════════════════════════════════════════════════
│  트레이너 영역 (Trainer Shell — NavigationBar/NavigationRail)
│  ※ NotificationBadge 오버레이: 모바일 앱바 아이콘 / 태블릿 NavigationRail trailing
├══════════════════════════════════════════════════════════════
│
├── /trainer (TrainerHomeScreen) ────────────── 탭 ①: 홈
│   ├── [대시보드 통계]  총 클라이언트, 이번 주 세션, 이번 달 세션
│   ├── [오늘의 세션]    스케줄된 세션 목록
│   ├── [최근 클라이언트] 빠른 접근 카드
│   ├── [클라이언트 활동] 최근 활동 피드
│   └── [빠른 액션]      새 클라이언트 추가, 세션 시작 등
│
├── /trainer/calendar (CalendarScreen) ──────── 탭 ②: 캘린더
│   ├── [월간 캘린더 뷰]  table_calendar 위젯
│   ├── [스케줄 카드]     일별 세션 목록
│   ├── [빠른 스케줄]     QuickScheduleSheet (bottom sheet)
│   └── [스케줄 편집]     EditScheduleSheet (bottom sheet)
│
├── /trainer/clients (ClientsListScreen) ────── 탭 ③: 클라이언트
│   │   ※ 태블릿(≥600px): ClientsMasterDetailScreen (마스터-디테일)
│   │
│   ├── /trainer/clients/add (AddClientScreen)
│   │     └── 새 클라이언트 직접 등록
│   │
│   ├── /trainer/clients/connect (ConnectClientScreen)
│   │     └── 기존 사용자 연결 요청
│   │
│   ├── /trainer/clients/invite (CreateInviteScreen)
│   │     └── QR코드 + 초대코드 생성
│   │
│   └── /trainer/clients/:id (ClientDetailScreen)
│         ├── [클라이언트 정보]  프로필, 목표, 장비
│         ├── [세션 히스토리]    완료된 세션 목록
│         ├── [근육 맵]         SVG 바디맵 (7/14/30일)
│         ├── [활성 프로그램]    현재 AI 프로그램
│         │
│         ├── /trainer/clients/:id/stats (ClientStatsScreen)
│         │     ├── [운동 통계]   볼륨 차트, 운동별 기록
│         │     ├── [라이프 로그] 식단/수면/기분/수분 요약
│         │     └── [세션 히스토리] 전체 목록
│         │
│         ├── ─→ /trainer/session/review/:clientId
│         │       (PreviousSessionReviewScreen)
│         │       └── 이전 세션 기반 새 세션 시작
│         │
│         ├── ─→ /trainer/session/:clientId
│         │       (ActiveSessionScreen) ★ 핵심 화면
│         │       ├── [운동 카드]       현재 운동 + 세트 기록
│         │       ├── [세트 로그]       무게/횟수/RPE/태그/코멘트
│         │       ├── [휴식 타이머]     카운트다운
│         │       ├── [운동 추가]       ExercisePickerDialog
│         │       ├── [운동 히스토리]   이전 세션 세트 비교
│         │       ├── [근육 바디맵]     세션 중 근육 활성화
│         │       └── [세션 완료]       → SessionSummaryScreen
│         │
│         ├── ─→ /trainer/session-summary/:sessionId
│         │       (SessionSummaryScreen)
│         │       ├── [세션 요약 통계]  총 볼륨, 세트수, 시간
│         │       ├── [달성 기록]       자동 감지된 PR/성취
│         │       └── [리포트 생성]     → ReportViewScreen
│         │
│         ├── ─→ /trainer/program/generate/:clientId
│         │       (GenerateProgramScreen)
│         │       ├── [프로그램 설정]   분할, 목표, 장비
│         │       └── [AI 생성]        Edge Function 호출
│         │
│         ├── ─→ /trainer/program/review/:programId
│         │       (ProgramReviewScreen)
│         │       └── 프로그램 상세 조회/편집
│         │
│         ├── ─→ /trainer/ai-exercises/review/:clientId
│         │       (AIExerciseReviewScreen)
│         │       ├── [AI 추천 운동]   운동별 AI 근거
│         │       ├── [운동 교체]      ExerciseSwapSheet
│         │       └── [세션 시작]      → ActiveSessionScreen
│         │
│         └── ─→ /trainer/report/:sessionId
│               (ReportViewScreen)
│               ├── [세션 리포트]     AI 생성 분석
│               ├── [운동별 분석]     볼륨/강도 비교
│               ├── [근육 맵 요약]   세션 근육 활성화
│               └── [HTML 공유]      리포트 URL 생성
│
├── /trainer/academy (AcademyScreen) ────────── 탭 ④: 아카데미
│   ├── [카테고리 필터]   CategoryChipBar
│   └── [영상 목록]       YouTubePlayerWidget
│
├── /trainer/profile (TrainerProfileScreen) ──── 탭 ⑤: 프로필
│   ├── [프로필 정보]     이름, 사진, 역할
│   ├── → /settings (SettingsScreen) ← 앱 설정
│   │     └── → /settings/notifications (알림 설정) ← ⚠️ 미구현
│   └── [로그아웃]
│
├── /trainer/templates (MyTemplatesScreen) ──── 독립 화면
│   ├── /trainer/templates/create (TemplateEditorScreen)
│   ├── /trainer/templates/edit/:id (TemplateEditorScreen 편집모드)
│   └── /trainer/templates/review/:clientId (TemplateReviewScreen)
│
├── /notifications (NotificationsScreen) ──── 독립 화면 (Trainer + Client 공통)
│   ├── [알림 목록]     유형별 알림 카드 (세션 리마인더, 리포트, 트레이너 메시지 등)
│   ├── [읽음 처리]     항목 탭 → mark as read
│   └── [스와이프 삭제] 개별 알림 삭제
│   ※ deep-link 알림 탭 시 해당 화면으로 자동 이동 (_handleNotificationTap)
│
├── /settings (SettingsScreen) ──────────── 독립 화면
│   └── [앱 설정]       ← 추후 확장 예정
│   ※ /settings/notifications — 알림 유형별 토글 ← ⚠️ 미구현 (서비스 메서드 존재)
│
│
├══════════════════════════════════════════════════════════════
│  클라이언트 영역 (Client Shell — NavigationBar 4탭)
├══════════════════════════════════════════════════════════════
│
├── /client (ClientHomeScreen) ──────────────── 탭 ①: 오늘
│   ├── [오늘의 라이프 로그]  식단/수분/수면/기분
│   ├── [트레이너 연결 상태]  연결됨 / 초대 대기
│   └── [최근 세션 요약]      마지막 완료 세션
│
├── /client/sessions (ClientSessionsScreen) ─── 탭 ②: 세션
│   ├── [세션 기록 목록]      완료된 세션 카드
│   └── ─→ /client/report/:reportId (ClientReportDetailScreen)
│         └── ─→ /client/session-report/:sessionId
│
├── /client/stats (ClientStatsScreen) ──────── 탭 ③: 통계
│   ├── [운동 통계]           볼륨 트렌드 차트
│   ├── [운동별 상세]         ExerciseDetailSheet
│   └── [라이프 로그 요약]    주간/월간 통계
│
├── /client/profile (ClientProfileScreen) ──── 탭 ④: 프로필
│   ├── [프로필 정보]         이름, 목표, 사진
│   ├── [트레이너 연결]       연결 상태
│   └── [로그아웃]
│
├── /client/invite (AcceptInviteScreen) ──── 독립 화면
│   └── /client/invite/:code
│         └── 초대코드 입력/딥링크로 수락
│
└── /client/record (ClientRecordScreen) ──── 독립 화면
      └── 라이프 로그 상세 기록
```

### 3.2 기능 모듈 구조 (Feature Modules)

```
lib/
├── main.dart                          # 앱 진입점
├── app.dart                           # MaterialApp.router (Material 3)
│
├── core/                              # 공통 인프라
│   ├── config/                        # supabase_config, app_config
│   ├── constants/                     # api_constants, app_constants
│   ├── error/                         # Failure 클래스 계층
│   ├── extensions/                    # context, datetime, string
│   ├── services/                      # rest_timer, notification_service, exercisedb
│   ├── theme/                         # app_theme, colors, typography, spacing
│   └── utils/                         # validators, formatters, helpers
│
├── shared/                            # 공유 컴포넌트
│   ├── models/                        # Result<T>, UserRole
│   ├── services/                      # LoggerService
│   ├── screens/                       # NotificationsScreen, SettingsScreen
│   └── widgets/                       # buttons, inputs, cards, exercise_picker, NotificationBadge
│
├── providers/                         # 루트 프로바이더
│   └── supabase_provider.dart         # SupabaseClient, Auth, Storage
│
├── navigation/                        # 라우팅
│   ├── app_router.dart                # GoRouter + Shell 정의
│   └── routes.dart                    # 라우트 상수
│
└── features/                          # 기능 모듈 (Clean Architecture)
    │
    ├── auth/                          # 인증
    │   ├── data/                      # datasource → model → repository_impl
    │   ├── domain/                    # entity → repository → usecase
    │   └── presentation/             # provider → screens (splash, login, register)
    │
    ├── trainer_home/                  # 트레이너 홈 대시보드
    │   └── presentation/             # provider → screens → widgets
    │
    ├── client_management/             # 클라이언트 관리
    │   ├── data/                      # client, invite, connection_request datasources
    │   ├── domain/                    # entities + 5 usecases (CRUD + delete)
    │   └── presentation/             # providers → 7 screens → widgets
    │
    ├── active_session/                # ★ 핵심: 실시간 운동 세션
    │   ├── data/                      # session + recommendation datasources
    │   ├── domain/                    # entities, services (3), usecases (5)
    │   └── presentation/             # providers (3) → screens (3) → widgets (16)
    │
    ├── ai_workout/                    # AI 운동 프로그램
    │   ├── data/                      # ai_workout + context_aggregator datasources
    │   ├── domain/                    # entities (6), repository
    │   └── presentation/             # provider → screens (3) → widgets (5)
    │
    ├── ai_report/                     # AI 세션 리포트
    │   ├── data/                      # report datasource
    │   ├── domain/                    # session_report entity
    │   └── presentation/             # provider → screen (1)
    │
    ├── lifestyle_log/                 # 라이프스타일 기록
    │   ├── data/                      # lifestyle datasource + 5 models
    │   ├── domain/                    # 9 entities + 6 usecases
    │   └── presentation/             # providers (3) → screens (6) → widgets (7)
    │
    ├── calendar/                      # 일정/스케줄 관리
    │   ├── data/                      # schedule + session_package datasources
    │   ├── domain/                    # 3 entities + 2 repositories
    │   └── presentation/             # provider → screen (1) → widgets (4)
    │
    ├── workout_templates/             # 운동 템플릿
    │   ├── data/                      # template datasource + 2 models
    │   ├── domain/                    # 2 entities + repository
    │   └── presentation/             # provider → screens (3) → widgets (3)
    │
    ├── muscle_map/                    # 근육 활성화 맵
    │   ├── data/                      # muscle_activity datasource
    │   ├── domain/                    # 3 entities + repository
    │   └── presentation/             # provider → widgets (7, 화면 없음)
    │
    ├── academy/                       # 교육 영상
    │   ├── data/                      # academy datasource + model
    │   ├── domain/                    # 2 entities + repository
    │   └── presentation/             # provider → screen (1) → widgets (3)
    │
    └── client_sessions/               # 클라이언트 세션 조회
        └── presentation/             # provider → screens (2) → widgets (2)
```

---

## 4. 화면 흐름도

### 4.1 인증 플로우 (Authentication Flow)

```
┌──────────┐
│  앱 시작  │
└────┬─────┘
     │
     ▼
┌──────────────┐     ┌─────────────┐
│ SplashScreen │────►│ authState   │
│     (/)      │     │ Provider    │
└──────────────┘     │ (Stream)    │
                     └──────┬──────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
              ▼             ▼             ▼
         [미인증]     [trainer]      [client]
              │             │             │
              ▼             ▼             ▼
     ┌────────────┐  ┌──────────┐  ┌──────────┐
     │ LoginScreen│  │ /trainer │  │ /client  │
     │  (/login)  │  │   홈     │  │   홈     │
     └──────┬─────┘  └──────────┘  └──────────┘
            │
     ┌──────┬──────────┐
     │      │          │
     ▼      ▼          ▼
[로그인] ┌────────┐ ┌──────────────────┐
[성공]   │Register│ │ForgotPasswordScreen│
     │   │Screen  │ │(/forgot-password)  │
     │   │(/reg.) │ │비밀번호 재설정 메일│
     │   └───┬────┘ └──────────────────┘
     │       │
     │                 │
     │          [역할 선택]
     │          trainer | client
     │                 │
     ▼                 ▼
┌──────────────────────────────────┐
│  Supabase Auth                   │
│  signInWithPassword() /          │
│  signUp(metadata: {role})        │
│                                  │
│  → accounts 테이블 조회/생성      │
│  → UserEntity(role) 반환          │
│  → authStateProvider 스트림 발행   │
│  → GoRouter redirect 실행         │
│  → 역할에 따라 /trainer 또는      │
│    /client로 리다이렉트           │
└──────────────────────────────────┘
```

### 4.2 트레이너 메인 플로우

```
┌────────────────────────────────────────────────────────────────────┐
│  Trainer Shell (NavigationBar / NavigationRail)                     │
│                                                                    │
│  ┌─────┐  ┌─────┐  ┌───────┐  ┌──────┐  ┌──────┐                │
│  │ 홈  │  │캘린더│  │클라이언트│  │아카데미│  │프로필│                │
│  │ ①  │  │ ②  │  │  ③   │  │  ④  │  │ ⑤  │                │
│  └──┬──┘  └──┬──┘  └───┬───┘  └──┬──┘  └──┬──┘                │
│     │        │         │         │        │                    │
└─────┼────────┼─────────┼─────────┼────────┼────────────────────┘
      │        │         │         │        │
      ▼        ▼         ▼         ▼        ▼
 [대시보드] [일정관리]  [목록/검색]  [영상]  [설정]
      │                  │
      │         ┌────────┼────────────────┐
      │         ▼        ▼                ▼
      │    [클라이언트  [추가/연결       [초대생성]
      │     상세]       /초대]
      │         │
      │         ├──────────────────────────────────────────┐
      │         │                                          │
      │    ┌────┴────┐   ┌──────────┐   ┌──────────┐     │
      │    │이전 세션 │   │AI 프로그램│   │  리포트  │     │
      │    │리뷰     │   │  생성    │   │  조회    │     │
      │    └────┬────┘   └────┬─────┘   └──────────┘     │
      │         │             │                           │
      │         │        ┌────┴─────┐                     │
      │         │        │AI 운동    │                     │
      │         │        │리뷰/교체  │                     │
      │         │        └────┬─────┘                     │
      │         │             │                           │
      │         └──────┬──────┘                           │
      │                ▼                                  │
      │    ╔══════════════════════╗                       │
      │    ║  Active Session ★   ║                       │
      │    ║  (핵심 기능)         ║                       │
      │    ╚══════════╤═════════╝                        │
      │               │                                  │
      │               ▼                                  │
      │    ┌──────────────────┐                          │
      │    │ Session Summary  │──────► Report 생성       │
      │    │ (세션 완료 후)    │                          │
      │    └──────────────────┘                          │
      │                                                  │
      └──────────────────────────────────────────────────┘
```

### 4.3 운동 세션 플로우 (Active Session — Core Flow)

```
세션 시작 경로 (3가지)
═══════════════════

경로 A: 빈 세션                경로 B: 이전 세션 기반          경로 C: AI 생성
─────────────────              ────────────────────           ────────────
ClientDetailScreen             PreviousSessionReview          GenerateProgram
    │                              Screen                        Screen
    │ "세션 시작"                    │                              │
    │                          [이전 세션 운동                  [AI 설정 입력]
    │                           수정/확인]                         │
    │                              │                          [Edge Function
    │                              │                           호출 → AI 운동
    │                              │                           생성]
    │                              │                              │
    │                              │                      AIExerciseReview
    │                              │                          Screen
    │                              │                      [운동 교체/확인]
    │                              │                              │
    └──────────────┬───────────────┴──────────────────────────────┘
                   │
                   ▼
    ╔══════════════════════════════════════════════════════╗
    ║              ActiveSessionScreen                     ║
    ║                                                      ║
    ║  ┌─────────────────────────────────────────┐        ║
    ║  │         운동 카드 (Exercise Card)        │        ║
    ║  │                                         │        ║
    ║  │  운동명 | GIF 썸네일 | 히스토리 버튼     │        ║
    ║  │                                         │        ║
    ║  │  ┌───────────────────────────────┐      │        ║
    ║  │  │  세트 로그 (Set Row)           │      │        ║
    ║  │  │  #1  60kg × 12  RPE 7  ✅    │      │        ║
    ║  │  │  #2  60kg × 10  RPE 8  ✅    │      │        ║
    ║  │  │  #3  (현재 입력 중)            │      │        ║
    ║  │  └───────────────────────────────┘      │        ║
    ║  │                                         │        ║
    ║  │  ┌────────┐ ┌────────┐ ┌────────┐      │        ║
    ║  │  │무게 조절│ │횟수 선택│ │RPE 슬라│      │        ║
    ║  │  │Adjuster│ │Selector│ │이더    │      │        ║
    ║  │  └────────┘ └────────┘ └────────┘      │        ║
    ║  │                                         │        ║
    ║  │  [태그: Warm-up, PR, Drop, Failure]     │        ║
    ║  │  [코멘트: Form, Pain, Memo 등]          │        ║
    ║  │                                         │        ║
    ║  │  ┌──────────────┐ ┌──────────────┐     │        ║
    ║  │  │  세트 기록   │ │  반복       │     │        ║
    ║  │  │  (Log Set)   │ │  (Repeat)   │     │        ║
    ║  │  └──────┬───────┘ └──────────────┘     │        ║
    ║  └─────────┼───────────────────────────────┘        ║
    ║            │                                         ║
    ║            ▼                                         ║
    ║  ┌─────────────────┐                                ║
    ║  │  휴식 타이머    │  ← 세트 로그 후 자동 시작       ║
    ║  │  (Rest Timer)   │     goalRestSeconds 기반        ║
    ║  └─────────────────┘                                ║
    ║                                                      ║
    ║  ┌─────────────────┐                                ║
    ║  │  운동 추가 FAB  │  → ExercisePickerDialog        ║
    ║  │  (+)            │     ├── 패밀리 → 변형 필터     ║
    ║  └─────────────────┘     ├── 추천 운동 (3-tier)     ║
    ║                          └── 검색 (이름/별칭)       ║
    ║                                                      ║
    ║  [세션 완료] ─────────────────────────────────────►  ║
    ╚══════════════════════════════════════╤═══════════════╝
                                           │
                                           ▼
                              ┌──────────────────────┐
                              │  SessionSummaryScreen │
                              │                      │
                              │  총 운동: N개         │
                              │  총 세트: M세트       │
                              │  총 볼륨: X kg        │
                              │  운동 시간: HH:MM     │
                              │  평균 RPE: Y.Z        │
                              │                      │
                              │  [달성 기록]          │
                              │  - 최고 무게 PR       │
                              │  - 볼륨 PR            │
                              │  - 연속 기록          │
                              │                      │
                              │  [리포트 생성] ──────►│ ReportViewScreen
                              └──────────────────────┘
```

### 4.4 세트 기록 상세 흐름

```
[무게/횟수/RPE 입력]
        │
        ▼
┌──────────────┐     ┌──────────────────────────┐
│  "세트 기록" │────►│  activeSessionProvider    │
│  버튼 탭     │     │  .notifier.logSet()       │
└──────────────┘     └────────────┬─────────────┘
                                  │
                     ┌────────────┼────────────────────┐
                     │            │                    │
                     ▼            ▼                    ▼
              [SessionRepo]  [State 업데이트]      [타이머 시작]
              .logSet()      currentExercise      _startCountdown
                     │       .sets += [newSet]    (goalRestSeconds)
                     │            │
                     ▼            ▼
              ┌────────────┐  [입력값 리셋]
              │ INSERT INTO │  RPE → 7.0
              │ set_records │  tags → clear
              └──────┬─────┘  comments → 유지
                     │
                     ▼
              [DB Trigger]
              update_exercise
              _familiarity
              (자동 실행)
```

### 4.5 클라이언트 메인 플로우

```
┌────────────────────────────────────────────────────────────┐
│  Client Shell (NavigationBar — 4탭)                        │
│                                                            │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐                 │
│  │ 오늘 │  │ 세션 │  │ 통계 │  │프로필│                 │
│  │  ①  │  │  ②  │  │  ③  │  │  ④  │                 │
│  └──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘                 │
└─────┼────────┼────────┼────────┼──────────────────────────┘
      │        │        │        │
      ▼        ▼        ▼        ▼

 [오늘 요약]  [세션 목록] [볼륨 차트] [프로필]
      │             │        │        │
      │             ▼        ▼        │
      │     [세션 상세]  [운동별     │
      │         │        상세]      │
      │         ▼                   │
      │    [리포트 조회]            │
      │    ClientReport             │
      │    DetailScreen             │
      │                             │
      ├── [식단 기록]               │
      ├── [수분 기록]               │
      ├── [수면 기록]               │
      ├── [기분 기록]               │
      └── [바디 사진]               │
                                    │
                              [로그아웃]
                              [초대 수락]
```

### 4.6 클라이언트 연결 플로우

```
트레이너 측                              클라이언트 측
─────────                               ──────────

방법 1: 초대 코드
┌──────────────┐                   ┌──────────────┐
│CreateInvite  │   코드/QR 전달    │AcceptInvite  │
│Screen        │ ──────────────►  │Screen        │
│              │                   │              │
│[QR코드 생성] │                   │[코드 입력    │
│[코드 복사]   │                   │ 또는 딥링크] │
└──────┬───────┘                   └──────┬───────┘
       │                                  │
       ▼                                  ▼
┌────────────────────────────────────────────────┐
│  trainer_invites 테이블                         │
│  code, trainer_id, status                       │
│                                                │
│  수락 시:                                       │
│  INSERT trainer_client_relationships            │
│  (trainer_id, client_id, status: 'active')      │
└────────────────────────────────────────────────┘

방법 2: 연결 요청
┌──────────────┐                   ┌──────────────┐
│ConnectClient │   요청 전송       │              │
│Screen        │ ──────────────►  │ (자동 수락)  │
│              │                   │              │
│[이메일로     │                   │              │
│ 클라이언트   │                   │              │
│ 검색]        │                   │              │
└──────┬───────┘                   └──────────────┘
       │
       ▼
┌────────────────────────────────────────────────┐
│  connection_requests 테이블                      │
│  trainer_id, client_id, status                  │
│                                                │
│  PendingRequestBanner 표시 (트레이너 홈)         │
└────────────────────────────────────────────────┘
```

---

## 5. 데이터 흐름도

### 5.1 Clean Architecture 레이어

```
┌─────────────────────────────────────────────────────────────────┐
│                        UI Layer                                  │
│  Screens → Widgets → ref.watch(provider)                        │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  Presentation Layer                        │  │
│  │  StateNotifier<State> / FutureProvider / StreamProvider    │  │
│  │                                                           │  │
│  │  ┌────────────────────────────────────────────────────┐   │  │
│  │  │                  Domain Layer                       │   │  │
│  │  │  Entity, Repository (interface), UseCase, Service   │   │  │
│  │  │                                                     │   │  │
│  │  │  ┌─────────────────────────────────────────────┐   │   │  │
│  │  │  │                Data Layer                    │   │   │  │
│  │  │  │  Model, RepositoryImpl, RemoteDataSource     │   │   │  │
│  │  │  │                                              │   │   │  │
│  │  │  │  ┌──────────────────────────────────────┐   │   │   │  │
│  │  │  │  │         External Layer                │   │   │   │  │
│  │  │  │  │  Supabase (PostgREST, Auth, Storage)  │   │   │   │  │
│  │  │  │  │  Edge Functions (AI)                  │   │   │   │  │
│  │  │  │  └──────────────────────────────────────┘   │   │   │  │
│  │  │  └─────────────────────────────────────────────┘   │   │  │
│  │  └────────────────────────────────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

데이터 흐름 방향:
  UI ──ref.watch──► Provider ──repository──► DataSource ──query──► Supabase
  UI ◄──state.copyWith── Provider ◄──Result<T>── Repository ◄──Model── DataSource

에러 처리:
  모든 Repository 메서드 → Future<Result<T>> = Future<Either<Failure, T>>
  Provider에서 fold() 패턴으로 에러/성공 분기
```

### 5.2 Provider 의존성 그래프 (핵심)

```
supabaseClientProvider (root)
    │
    ├──► supabaseAuthProvider
    │         │
    │         └──► authStateProvider (StreamProvider<UserEntity?>)
    │                    │
    │                    ├──► routerProvider (GoRouter redirect)
    │                    │
    │                    └──► currentUserProvider
    │
    ├──► authRemoteDataSourceProvider
    │         │
    │         └──► authRepositoryProvider
    │                    │
    │                    ├──► loginUseCaseProvider
    │                    ├──► registerUseCaseProvider
    │                    └──► logoutUseCaseProvider
    │                              │
    │                              └──► authNotifierProvider
    │
    ├──► clientRemoteDataSourceProvider
    │         │
    │         └──► clientRepositoryProvider
    │                    │
    │                    └──► clientsProvider ──► filteredClientsProvider
    │                              │
    │                              └──► dashboardStatsProvider
    │
    ├──► sessionRemoteDataSourceProvider
    │         │
    │         └──► sessionRepositoryProvider
    │                    │
    │                    ├──► activeSessionProvider ★
    │                    │         │
    │                    │         └──► contextualRecommendationsProvider
    │                    │
    │                    ├──► exerciseLibraryProvider
    │                    ├──► recentExercisesProvider
    │                    ├──► clientRecentSessionsProvider
    │                    └──► clientSessionHistoryProvider
    │
    ├──► recommendationRemoteDataSourceProvider
    │         │
    │         └──► recommendationRepositoryProvider
    │                    │
    │                    ├──► recommendationWeightsProvider ─┐
    │                    ├──► userPreferencesProvider ───────┤
    │                    └──► exerciseRelationsProvider ─────┤
    │                                                       │
    │                    exerciseRecommendationServiceProvider
    │                              │
    │                              └──► exerciseRecommendationsProvider
    │
    ├──► aiWorkoutRepositoryProvider
    │         │
    │         ├──► programCreationProvider
    │         ├──► clientProgramsProvider
    │         └──► activeProgramProvider ──► exerciseRecommendationsProvider
    │
    ├──► reportRepositoryProvider
    │         │
    │         └──► reportGenerationProvider
    │
    └──► muscleActivityRepositoryProvider
              │
              ├──► clientMuscleMapProvider (7/14/30일)
              └──► muscleMapScreenProvider
```

---

## 6. Critical Path 분석

### 6.1 Critical Path 정의

서비스의 **Critical Path**는 사용자의 핵심 가치를 전달하는 최소 경로이다.
FitLog Pro에서 가장 중요한 경로는 **"트레이너가 클라이언트의 운동 세션을 기록하는 것"**이다.

### 6.2 Primary Critical Path: 운동 세션 기록

```
중요도: ★★★★★ (서비스 존재 이유)
실패 시 영향: 서비스 핵심 가치 상실 — 운동 데이터 손실

경로:
Login → ClientDetail → ActiveSession → LogSets → Complete → Summary

상세 단계:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

① 인증 (Authentication)
   Supabase Auth → accounts 조회 → UserEntity 반환
   ⚠️ 실패 지점: 네트워크 오류, 토큰 만료
   🔒 필수 조건: 유효한 세션 토큰

② 클라이언트 선택 (Client Selection)
   clientsProvider → Supabase query → ClientEntity 목록
   ⚠️ 실패 지점: RLS 정책 오류, 빈 클라이언트 목록
   🔒 필수 조건: trainer_client_relationships 존재

③ 세션 생성 (Session Creation)
   activeSessionProvider.createSession(clientId)
   → INSERT sessions (status: 'active')
   ⚠️ 실패 지점: DB 쓰기 실패, 동시 세션 충돌
   🔒 필수 조건: 유효한 clientId, 트레이너-클라이언트 관계

④ 운동 추가 (Exercise Addition)
   ExercisePicker → exerciseLibraryProvider → 236개 운동 로드
   → INSERT session_exercises
   ⚠️ 실패 지점: 운동 라이브러리 로딩 실패
   🔒 필수 조건: exercises 테이블 데이터

⑤ 세트 기록 (Set Logging) ★ 최핵심
   logSet() → INSERT set_records
   → 무게, 횟수, RPE, 태그, 코멘트 저장
   ⚠️ 실패 지점: DB 쓰기 실패 (데이터 손실)
   🔒 필수 조건: 활성 세션, 유효한 session_exercise_id
   ⏱️ 지연 허용: 최소 (사용자가 실시간으로 기록 중)

⑥ 세션 완료 (Session Completion)
   completeSession() → UPDATE sessions (status: 'completed')
   → 통계 계산 (total_volume, avg_rpe 등)
   → provider 무효화 (캐시 리프레시)
   → program focus 업데이트
   ⚠️ 실패 지점: 통계 계산 오류, provider 무효화 누락
   🔒 필수 조건: 최소 1개 세트 기록됨
```

### 6.3 Critical Path 의존성 체인

```
┌─────────────┐
│  Supabase   │ ← 단일 장애점 (SPOF)
│  Backend    │
└──────┬──────┘
       │
       ├── Auth Service (PKCE)
       │     └── 토큰 갱신, 세션 유지
       │
       ├── PostgREST API
       │     ├── accounts 테이블
       │     ├── trainer_client_relationships 테이블
       │     ├── sessions 테이블
       │     ├── session_exercises 테이블
       │     ├── exercises 테이블 (236 rows, read-only)
       │     └── set_records 테이블 ★
       │
       ├── RLS Policies
       │     └── trainer_id / client_id 기반 접근 제어
       │
       └── DB Triggers
             └── update_exercise_familiarity
             └── auto_increment_sessions_used
```

### 6.4 Secondary Critical Paths

```
경로 2: AI 프로그램 생성 (★★★★☆)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Login → ClientDetail → GenerateProgram → Edge Function
→ AIExerciseReview → ActiveSession

추가 의존성:
  - Supabase Edge Functions (AI 백엔드)
  - context_aggregator_datasource (클라이언트 컨텍스트 수집)
  - 외부 AI 서비스 (Edge Function 내부)

실패 시 영향:
  - AI 추천 불가 → 수동 세션 생성으로 폴백 가능
  - 서비스 핵심은 아니지만 차별화 요소

경로 3: 세션 리포트 생성/조회 (★★★☆☆)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SessionSummary → GenerateReport → Edge Function
→ HTML Storage → ReportView → 공유

추가 의존성:
  - Supabase Edge Functions
  - Supabase Storage (session_reports 버킷)
  - HTML 렌더링

실패 시 영향:
  - 리포트 생성 불가 → 세션 요약은 여전히 로컬에서 조회 가능
  - 클라이언트 공유 불가

경로 4: 클라이언트 연결 (★★★☆☆)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CreateInvite → 코드/QR 전달 → AcceptInvite → 관계 생성

실패 시 영향:
  - 새 클라이언트 온보딩 불가
  - 기존 연결된 클라이언트에는 영향 없음

경로 5: 라이프 로그 기록 (★★☆☆☆)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ClientHome → 식단/수분/수면/기분 입력 → Supabase INSERT

실패 시 영향:
  - 라이프 로그 데이터 누락
  - 세션 기록에는 직접 영향 없음
```

### 6.5 Critical Path 리스크 매트릭스

```
┌─────────────────────────┬──────────┬───────────┬───────────────────┐
│ 리스크                   │ 확률     │ 영향도    │ 완화 방안          │
├─────────────────────────┼──────────┼───────────┼───────────────────┤
│ Supabase 서비스 장애     │ 낮음     │ ★★★★★  │ 오프라인 모드 (미구│
│                         │          │ (전면 중단)│  현, Drift 준비됨) │
├─────────────────────────┼──────────┼───────────┼───────────────────┤
│ 네트워크 연결 끊김       │ 중간     │ ★★★★☆  │ 로컬 캐시 + 재시도 │
│ (세션 중)               │          │ (세트 손실)│ (미구현)          │
├─────────────────────────┼──────────┼───────────┼───────────────────┤
│ RLS 정책 오류           │ 낮음     │ ★★★★☆  │ 마이그레이션 테스트│
│                         │          │ (접근 차단)│                   │
├─────────────────────────┼──────────┼───────────┼───────────────────┤
│ Edge Function 타임아웃   │ 중간     │ ★★★☆☆  │ 수동 모드 폴백     │
│ (AI 기능)               │          │ (AI 불가) │                   │
├─────────────────────────┼──────────┼───────────┼───────────────────┤
│ 토큰 만료 (세션 중)     │ 낮음     │ ★★★☆☆  │ Supabase 자동 갱신│
│                         │          │ (재인증)  │                   │
├─────────────────────────┼──────────┼───────────┼───────────────────┤
│ 동시 세션 충돌          │ 낮음     │ ★★☆☆☆  │ UI 레벨 방지      │
│                         │          │ (데이터   │ (서버 제약 없음)  │
│                         │          │  불일치)  │                   │
├─────────────────────────┼──────────┼───────────┼───────────────────┤
│ 운동 라이브러리 로딩     │ 낮음     │ ★★☆☆☆  │ 캐시/로컬 DB      │
│ 실패                    │          │ (운동 추가│ (Drift 준비됨)    │
│                         │          │  불가)    │                   │
└─────────────────────────┴──────────┴───────────┴───────────────────┘
```

### 6.6 Critical Path 성능 병목점

```
병목 1: 세션 데이터 로딩 (ActiveSessionScreen)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
쿼리: sessions → session_exercises → exercises → set_records
복잡도: 4-depth nested join
크기: 세션당 ~6-10 운동 × ~3-5 세트 = ~30-50 set_records

최적화 상태:
  ✅ Supabase nested select (단일 쿼리)
  ✅ Index: session_exercises(session_id), set_records(session_exercise_id)
  ⚠️ 미최적화: 세트 추가 시 전체 세션 re-fetch

병목 2: 운동 라이브러리 검색
━━━━━━━━━━━━━━━━━━━━━━━━━━
쿼리: exercises 테이블 전체 로드 (236개)
현재: 매 검색 시 서버 조회
최적화 가능: 로컬 캐시 (Drift 의존성 이미 존재)

병목 3: 추천 엔진
━━━━━━━━━━━━━━━━
쿼리: recommendation_weights + user_preferences + exercise_relations
동시 3개 비동기 쿼리 → 서비스에서 점수 계산
최적화 상태:
  ✅ 클라이언트 사이드 계산 (서버 부하 없음)
  ⚠️ exerciseRecommendationsProvider: 다수 provider 동시 watch

병목 4: Provider 캐시 무효화 (세션 완료 시)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
completeSession() 시 8+ provider invalidate:
  - clientRecentSessionsProvider
  - recentExercisesProvider
  - clientMuscleMapProvider (×4 time ranges)
  - activeProgramProvider
  - exerciseRecommendationsProvider
연쇄 re-fetch 발생 가능
```

---

## 7. 데이터베이스 ER 구조

### 7.1 핵심 테이블 관계

```
                                    ┌──────────────────┐
                                    │   auth.users     │
                                    │ (Supabase Auth)  │
                                    └────────┬─────────┘
                                             │ user_id
                                             ▼
┌──────────────────┐               ┌──────────────────┐
│  trainer_invites  │               │    accounts      │
│                   │               │                  │
│  code             │◄──────────────│  id (PK)         │
│  trainer_id (FK)  │   trainer_id  │  user_id (FK)    │
│  status           │               │  full_name       │
└──────────────────┘               │  role             │
                                    │  fitness_goals    │
                                    │  profile_image_url│
                                    └───┬──────────┬───┘
                                        │          │
                          trainer_id ───┘          └─── client_id
                                        │          │
                              ┌─────────┴──┐  ┌───┴──────────┐
                              │   trainer   │  │    client     │
                              │   측 참조   │  │    측 참조    │
                              └──────┬──────┘  └──────┬───────┘
                                     │                │
                                     ▼                ▼
                         ┌───────────────────────────────────┐
                         │  trainer_client_relationships      │
                         │                                    │
                         │  trainer_id (FK → accounts)        │
                         │  client_id  (FK → accounts)        │
                         │  status: active | inactive         │
                         └───────────────────────────────────┘
                                     │
                    ┌────────────────┼────────────────┐
                    │                │                │
                    ▼                ▼                ▼
         ┌──────────────┐  ┌──────────────┐  ┌────────────────┐
         │   sessions   │  │workout_      │  │client_schedules│
         │              │  │programs      │  │                │
         │ id (PK)      │  │              │  │ trainer_id     │
         │ trainer_id   │  │ id (PK)      │  │ client_id      │
         │ client_id    │  │ client_id    │  │ scheduled_at   │
         │ program_id   │──│ trainer_id   │  │ status         │
         │ status       │  │ training_    │  └────────────────┘
         │ focus_area   │  │   split      │
         │ duration_sec │  │ focus_areas  │
         │ total_volume │  │ status       │
         │ avg_rpe      │  └──────────────┘
         │ completed_at │
         └───────┬──────┘
                 │
                 ▼
      ┌─────────────────────┐       ┌──────────────────┐
      │  session_exercises  │       │    exercises      │
      │                     │       │                   │
      │  id (PK)            │       │  id (PK)          │
      │  session_id (FK)    │       │  name              │
      │  exercise_id (FK) ──┼──────►│  name_ko           │
      │  order_index        │       │  movement_group    │
      │  target_sets        │       │  movement_detail   │
      │  target_reps        │       │  family            │
      │  target_weight      │       │  angle             │
      │  notes (JSONB)      │       │  muscle_group      │
      │  completed_at       │       │  equipment         │
      └─────────┬───────────┘       │  category          │
                │                   │  exercise_type     │
                │                   │  gif_url           │
                ▼                   └──────────────────┘
      ┌─────────────────────┐
      │    set_records      │
      │                     │
      │  id (PK)            │
      │  session_exercise_id│
      │  set_number         │
      │  weight             │
      │  reps               │
      │  rpe                │
      │  duration_seconds   │
      │  tags (TEXT[])      │
      │  pr_type            │
      │  comments (JSONB)   │
      │  completed_at       │
      └─────────────────────┘
```

### 7.2 보조 테이블 관계

```
라이프 로그 (모두 client_id → accounts)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  accounts.id ──┬──► meal_logs    (식단: 종류, 칼로리, 매크로)
                ├──► mood_logs    (기분: 1-5, 에너지, 스트레스)
                ├──► sleep_logs   (수면: 취침/기상, 품질 1-5)
                ├──► water_logs   (수분: ml 단위)
                └──► body_photos  (사진: 각도, URL, 체중)


추천 시스템
━━━━━━━━━━

  exercises ──┬──► exercise_aliases           (별칭 검색용)
              ├──► exercise_relations          (상보/보충 운동 관계)
              └──► client_exercise_familiarity (자동 업데이트, 친숙도)

  accounts  ──┬──► recommendation_weights     (운동 추천 가중치)
              └──► user_preferences            (사용자 선호도)


AI & 리포트
━━━━━━━━━━━

  sessions  ──┬──► session_reports    (AI 리포트: summary, html_url)
              └──► session_exercise_feedback (운동별 난이도 피드백)

  accounts  ──► ai_generation_context (AI 생성 컨텍스트)

  exercises ──► exercise_swap_history (AI 운동 교체 이력)


기타
━━━━

  accounts  ──┬──► session_packages    (세션 패키지: 총 횟수/사용 횟수)
              ├──► workout_templates   (운동 템플릿: JSONB)
              └──► comment_usage       (코멘트 빈도 통계)

  academy_categories ──► academy_videos (교육 영상)
```

---

## 8. 상태 관리 의존성 맵

### 8.1 ActiveSessionState (가장 복잡한 상태)

```
ActiveSessionState
├── session: SessionEntity?
│     ├── id, trainerId, clientId, status
│     ├── exercises: List<SessionExerciseEntity>
│     │     └── sets: List<ExerciseSetEntity>
│     └── focusArea, duration, totalVolume, avgRpe
│
├── currentExerciseIndex: int
├── currentWeight: double          ← WeightAdjuster 위젯
├── currentReps: int               ← RepSelector 위젯
├── currentRpe: double             ← RPESlider 위젯
├── currentTags: List<SetTag>      ← SetTagSelector 위젯
├── currentComments: List<SetComment> ← SetCommentSelector 위젯
├── currentCommentDetails: Map     ← 코멘트 상세 텍스트
│
├── lastLoggedSet: ExerciseSetEntity?
├── exercisePR: ExerciseSetEntity? ← 1RM 기반 (Epley 공식)
├── lastSessionSets: List          ← 이전 세션 비교용
│
├── isTimerMode: bool              ← 등척성 운동용
├── countdownRemaining: int        ← 휴식 타이머 잔여초
├── isCountdownRunning: bool
├── goalRestSeconds: int           ← 클라이언트 목표 기반
│
├── exerciseComments: Map          ← 운동별 코멘트 (세션 전체)
├── exerciseMemos: Map             ← 운동별 메모 (세션 전체)
│
└── isLoading: bool
    error: String?
```

### 8.2 상태 변이 이벤트 맵

```
┌─────────────────┬──────────────────────────────────┬──────────────────┐
│ 이벤트          │ 상태 변이                         │ 부수 효과        │
├─────────────────┼──────────────────────────────────┼──────────────────┤
│ createSession   │ session = new, index = 0         │ DB INSERT        │
│ addExercise     │ session.exercises += [ex]        │ DB INSERT        │
│ goToExercise(i) │ index = i, weight/reps 초기화    │ 히스토리 로드     │
│ setWeight(w)    │ currentWeight = w                │ (없음, 로컬)     │
│ setReps(r)      │ currentReps = r                  │ (없음, 로컬)     │
│ setRpe(r)       │ currentRpe = r                   │ (없음, 로컬)     │
│ logSet()        │ sets += [newSet], rpe→7, tag→[]  │ DB INSERT, 타이머│
│ repeatLastSet   │ weight/reps 프리필               │ logSet() 호출    │
│ deleteSet(n)    │ sets.removeAt(n)                 │ DB DELETE        │
│ completeSession │ session = null (리셋)            │ DB UPDATE, 8+    │
│                 │                                  │ provider 무효화  │
│ toggleTimer     │ isCountdownRunning 토글          │ Timer.periodic   │
│ cancelSession   │ session = null                   │ DB UPDATE status │
└─────────────────┴──────────────────────────────────┴──────────────────┘
```

---

## 부록: 기술 스택 요약

| 레이어 | 기술 | 용도 |
|--------|------|------|
| **UI** | Flutter (Material 3) | 크로스 플랫폼 앱 |
| **상태 관리** | Riverpod 2.x | 의존성 주입 + 반응형 상태 |
| **라우팅** | GoRouter 13.x | 선언적 라우팅, 인증 가드 |
| **백엔드** | Supabase | Auth, DB, Storage, Edge Functions |
| **DB** | PostgreSQL (Supabase) | RLS 기반 보안, PostgREST API |
| **AI** | Supabase Edge Functions | 프로그램 생성, 리포트 생성 |
| **로컬 DB** | Drift (준비됨) | 오프라인 모드 (미활성화) |
| **에러 처리** | dartz (Either) | Result<T> = Either<Failure, T> |
| **데이터 클래스** | Freezed | 불변 객체 생성 |
| **차트** | fl_chart | 볼륨/통계 시각화 |
| **캘린더** | table_calendar | 월간 일정 뷰 |
| **바디맵** | flutter_svg | SVG 기반 근육 히트맵 