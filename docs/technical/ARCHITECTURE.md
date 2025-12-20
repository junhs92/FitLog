# FitLog Pro - Architecture Guide

Complete technical architecture documentation for developers.

---

## Table of Contents

1. [Overview](#overview)
2. [Directory Structure](#directory-structure)
3. [Architecture Patterns](#architecture-patterns)
4. [State Management](#state-management)
5. [Navigation](#navigation)
6. [Backend Integration](#backend-integration)
7. [Feature Modules](#feature-modules)
8. [Data Flow](#data-flow)
9. [Error Handling](#error-handling)
10. [Configuration](#configuration)
11. [Running the App](#running-the-app)

---

## Overview

FitLog Pro is an AI-powered personal training platform with dual user roles:

| Role | Purpose |
|------|---------|
| **Trainer** | Manage clients, log sessions, generate AI workouts |
| **Client** | Track lifestyle (meals, sleep, mood), view progress |

### Tech Stack

| Layer | Technology |
|-------|------------|
| UI | Flutter 3.16+ / Material 3 |
| State | Riverpod 2.4+ |
| Navigation | GoRouter 13+ |
| Backend | Supabase (PostgreSQL, Auth, Storage) |
| Local DB | Drift (SQLite) - prepared |
| Codegen | Freezed, JSON Serializable |
| Error Handling | dartz Either |

---

## Directory Structure

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # Root MaterialApp widget
│
├── navigation/
│   ├── app_router.dart          # GoRouter config with auth guards
│   └── routes.dart              # Route paths and names
│
├── providers/
│   └── supabase_provider.dart   # Supabase client injection
│
├── core/                        # Shared utilities
│   ├── config/
│   │   ├── app_config.dart      # Environment & feature flags
│   │   └── supabase_config.dart # Supabase initialization
│   ├── constants/
│   │   ├── app_constants.dart   # App-wide constants
│   │   └── api_constants.dart   # API endpoints
│   ├── error/
│   │   └── failures.dart        # Error type hierarchy
│   ├── extensions/              # Dart extensions
│   ├── theme/                   # Material 3 theming
│   │   ├── app_theme.dart
│   │   ├── colors.dart
│   │   ├── typography.dart
│   │   └── spacing.dart
│   └── utils/                   # Formatters, validators, helpers
│
├── shared/                      # Cross-feature resources
│   ├── models/
│   ├── services/
│   │   └── logger_service.dart
│   └── widgets/
│       ├── buttons/
│       ├── cards/
│       ├── common/
│       └── inputs/
│
└── features/                    # Feature modules
    ├── auth/
    ├── client_management/
    ├── active_session/
    ├── ai_workout/
    ├── ai_report/
    ├── lifestyle_log/
    ├── trainer_home/
    └── ...
```

---

## Architecture Patterns

### Clean Architecture (Feature-Based)

Each feature follows a three-layer architecture:

```
features/[feature]/
├── data/                        # Data layer
│   ├── datasources/             # API/local data sources
│   ├── models/                  # JSON serializable models
│   └── repositories/            # Repository implementations
│
├── domain/                      # Business logic layer
│   ├── entities/                # Pure business objects
│   ├── repositories/            # Abstract interfaces
│   └── usecases/                # Business operations
│
└── presentation/                # UI layer
    ├── providers/               # Riverpod providers
    ├── screens/                 # Page widgets
    └── widgets/                 # Reusable components
```

### Example: Auth Feature

```dart
// Domain Entity (pure business object)
class UserEntity {
  final String id;
  final String email;
  final String name;
  final UserRole role;  // trainer | client
  // ...
}

// Domain Repository Interface
abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, void>> logout();
}

// Data Repository Implementation
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, UserEntity>> login(email, password) async {
    try {
      final model = await _remoteDataSource.login(email, password);
      return Right(model.toEntity());
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}

// Use Case
class LoginUseCase {
  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call(String email, String password) {
    return _repository.login(email, password);
  }
}
```

---

## State Management

### Riverpod Provider Types

| Type | Use Case | Example |
|------|----------|---------|
| `Provider` | Computed values, DI | Repository injection |
| `StreamProvider` | Real-time data | Auth state changes |
| `FutureProvider` | Async fetching | Load client list |
| `StateNotifierProvider` | Complex state | Auth actions |

### Provider Pattern

```dart
// 1. Data source injection
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRemoteDataSource(client);
});

// 2. Repository injection
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

// 3. Use case injection
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

// 4. State stream (real-time)
final authStateProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// 5. State notifier (actions)
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
  );
});
```

### Using Providers in UI

```dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      loading: () => LoadingIndicator(),
      authenticated: (user) => TrainerHomeScreen(),
      error: (msg) => ErrorView(message: msg),
      // ...
    );
  }

  void _login(WidgetRef ref) {
    ref.read(authNotifierProvider.notifier).login(email, password);
  }
}
```

---

## Navigation

### Route Structure

```
/                           # Splash (auth check)
/login                      # Login screen
/register                   # Registration

/trainer                    # Trainer shell (bottom nav)
├── /trainer/clients        # Client list
├── /trainer/clients/add    # Add client
├── /trainer/clients/:id    # Client detail
├── /trainer/session/:clientId     # Active session
├── /trainer/session-summary/:id   # Session summary
├── /trainer/program/generate/:id  # AI program generation
├── /trainer/program/review/:id    # Program review
├── /trainer/academy        # Academy (placeholder)
└── /trainer/profile        # Profile (placeholder)

/client                     # Client shell (bottom nav)
├── /client/record          # Log lifestyle data
├── /client/stats           # Statistics
└── /client/profile         # Profile
```

### GoRouter Configuration

```dart
// lib/navigation/app_router.dart
final appRouter = GoRouter(
  initialLocation: Routes.splash,
  redirect: (context, state) {
    final isLoggedIn = /* check auth */;
    final isAuthRoute = state.matchedLocation == Routes.login;

    if (!isLoggedIn && !isAuthRoute) return Routes.login;
    if (isLoggedIn && isAuthRoute) {
      return user.isTrainer ? Routes.trainerHome : Routes.clientHome;
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),

    // Trainer shell with bottom navigation
    ShellRoute(
      builder: (_, __, child) => TrainerShell(child: child),
      routes: [
        GoRoute(path: '/trainer', builder: (_, __) => TrainerHomeScreen()),
        GoRoute(path: '/trainer/clients', builder: (_, __) => ClientsListScreen()),
        GoRoute(
          path: '/trainer/clients/:id',
          builder: (_, state) => ClientDetailScreen(
            clientId: state.pathParameters['id']!,
          ),
        ),
        // ...
      ],
    ),
  ],
);
```

### Navigation Usage

```dart
// Navigate to route
context.go('/trainer/clients');

// Navigate with parameters
context.go('/trainer/clients/${client.id}');

// Push (can go back)
context.push('/trainer/session/${clientId}');

// Named route
context.goNamed('trainerClientDetail', pathParameters: {'id': clientId});
```

---

## Backend Integration

### Supabase Setup

```dart
// lib/core/config/supabase_config.dart
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
```

### Supabase Providers

```dart
// lib/providers/supabase_provider.dart
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

final authSessionProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});
```

### Data Source Example

```dart
class ClientRemoteDataSource {
  final SupabaseClient _client;

  Future<List<ClientModel>> getClients(String trainerId) async {
    final response = await _client
        .from('clients')
        .select()
        .eq('trainer_id', trainerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ClientModel.fromJson(json))
        .toList();
  }

  Future<ClientModel> createClient(ClientModel client) async {
    final response = await _client
        .from('clients')
        .insert(client.toJson())
        .select()
        .single();

    return ClientModel.fromJson(response);
  }
}
```

---

## Feature Modules

### Auth (`lib/features/auth/`)

| Component | Purpose |
|-----------|---------|
| `UserEntity` | User data with role (trainer/client) |
| `SplashScreen` | Initial auth check |
| `LoginScreen` | Email/password login |
| `RegisterScreen` | Role-based registration |

### Client Management (`lib/features/client_management/`)

| Component | Purpose |
|-----------|---------|
| `ClientEntity` | Client profile with goals, health history |
| `ClientsListScreen` | Trainer's client list |
| `AddClientScreen` | Create new client |
| `ClientDetailScreen` | Full client profile |

### Active Session (`lib/features/active_session/`)

| Component | Purpose |
|-----------|---------|
| `SessionEntity` | Workout session with exercises |
| `ExerciseEntity` | Exercise definition |
| `ExerciseSetEntity` | Individual set data (reps, weight, RPE) |
| `ActiveSessionScreen` | Real-time workout logging |
| `SessionSummaryScreen` | Post-workout analysis |

### AI Workout (`lib/features/ai_workout/`)

| Component | Purpose |
|-----------|---------|
| `WorkoutProgramEntity` | Multi-week program |
| `WorkoutDayEntity` | Single workout day |
| `ProgramExerciseEntity` | Exercise with AI reasoning |
| `GenerateProgramScreen` | AI prompt form |
| `ProgramReviewScreen` | Review/customize program |

### Lifestyle Log (`lib/features/lifestyle_log/`)

| Component | Purpose |
|-----------|---------|
| `DailyLogEntity` | Aggregated daily data |
| `MealLogEntity` | Meal with macros |
| `SleepLogEntity` | Sleep tracking |
| `WaterLogEntity` | Hydration tracking |
| `MoodLogEntity` | Mood & energy |
| `ClientHomeScreen` | Today's overview |
| `ClientRecordScreen` | Log new data |

---

## Data Flow

### Example: Starting a Session

```
┌─────────────────────────────────────────────────────────┐
│  UI: ActiveSessionScreen                                │
│  User taps "Start Session"                              │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  Provider: sessionNotifier.startSession(clientId)       │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  UseCase: StartSessionUseCase.call(clientId, trainerId) │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  Repository: SessionRepositoryImpl.startSession()       │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  DataSource: Supabase INSERT → sessions table           │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  Return: Either<Failure, SessionEntity>                 │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  Provider updates state → UI rebuilds                   │
└─────────────────────────────────────────────────────────┘
```

---

## Error Handling

### Failure Hierarchy

```dart
// lib/core/error/failures.dart
abstract class Failure {
  final String message;
  final String? code;
}

class ServerFailure extends Failure { ... }
class NetworkFailure extends Failure { ... }
class AuthFailure extends Failure { ... }
class ValidationFailure extends Failure { ... }
class NotFoundFailure extends Failure { ... }
class PermissionFailure extends Failure { ... }
```

### Either Pattern

```dart
// Repository returns Either
Future<Either<Failure, ClientEntity>> getClient(String id) async {
  try {
    final model = await _dataSource.getClient(id);
    return Right(model.toEntity());
  } on NotFoundException {
    return Left(NotFoundFailure('Client not found'));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}

// UI handles Either
final result = await useCase.call(clientId);
result.fold(
  (failure) => showError(failure.message),
  (client) => navigateToClient(client),
);
```

---

## Configuration

### Environment Variables

Pass via `--dart-define` when running:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### App Config

```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';

  // Feature flags
  static const bool enableOfflineMode = true;
  static const bool enableVoiceInput = true;
  static const bool enableAIFeatures = true;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration syncInterval = Duration(minutes: 5);
}
```

---

## Running the App

### Setup

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Generate code** (freezed, json_serializable)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Create `.env` file** (copy from `.env.example`)
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=eyJ...
   ```

### Run Commands

```bash
# Mobile (auto-detect device)
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...

# Web (Chrome on port 3000)
flutter run -d chrome --web-port=3000 \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...

# Release build
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### VS Code Launch Config

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "FitLog Pro (Debug)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=SUPABASE_URL=https://xxx.supabase.co",
        "--dart-define=SUPABASE_ANON_KEY=eyJ..."
      ]
    },
    {
      "name": "FitLog Pro (Chrome)",
      "request": "launch",
      "type": "dart",
      "deviceId": "chrome",
      "args": [
        "--web-port=3000",
        "--dart-define=SUPABASE_URL=https://xxx.supabase.co",
        "--dart-define=SUPABASE_ANON_KEY=eyJ..."
      ]
    }
  ]
}
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `lib/main.dart` | App bootstrap & initialization |
| `lib/app.dart` | Root MaterialApp with theme |
| `lib/navigation/app_router.dart` | GoRouter with auth guards |
| `lib/navigation/routes.dart` | Route path constants |
| `lib/providers/supabase_provider.dart` | Supabase DI |
| `lib/core/config/app_config.dart` | Feature flags |
| `lib/core/config/supabase_config.dart` | Supabase init |
| `lib/core/error/failures.dart` | Error types |
| `lib/core/theme/app_theme.dart` | Material 3 theme |
| `lib/core/theme/colors.dart` | Color palette |

---

## Adding a New Feature

1. **Create directory structure**
   ```
   lib/features/new_feature/
   ├── data/
   │   ├── datasources/
   │   ├── models/
   │   └── repositories/
   ├── domain/
   │   ├── entities/
   │   ├── repositories/
   │   └── usecases/
   └── presentation/
       ├── providers/
       ├── screens/
       └── widgets/
   ```

2. **Define domain entity** (pure business object)

3. **Create repository interface** (abstract contract)

4. **Implement data layer** (models, datasource, repository impl)

5. **Create use cases** (single-purpose business operations)

6. **Build providers** (Riverpod state management)

7. **Create UI** (screens and widgets)

8. **Add routes** to `app_router.dart`

9. **Run codegen** for freezed/json_serializable:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

---

*Last updated: December 2024*
