# FitLog Pro - Flutter Implementation Guide

**Version:** 1.0
**Last Updated:** December 2024
**Parent Document:** TSD.md v1.2
**Purpose:** Flutter-specific implementation details and architecture patterns

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Flutter Project Structure](#2-flutter-project-structure)
3. [State Management Architecture](#3-state-management-architecture)
4. [Clean Architecture Implementation](#4-clean-architecture-implementation)
5. [Supabase Integration](#5-supabase-integration)
6. [Offline-First Strategy](#6-offline-first-strategy)
7. [UI/UX Implementation](#7-uiux-implementation)
8. [Testing Strategy](#8-testing-strategy)
9. [Performance Optimization](#9-performance-optimization)
10. [Build & Deployment](#10-build--deployment)

---

## 1. Introduction

### 1.1 Purpose

This document provides Flutter-specific implementation guidance for FitLog Pro, complementing the main TSD.md. It focuses on Flutter best practices, architecture patterns, and practical implementation details.

### 1.2 Technology Stack Summary

From TSD.md Section 2.2.1, our Flutter stack:

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Flutter | 3.16+ |
| Language | Dart | 3.2+ |
| State Management | Riverpod | 2.4+ |
| Navigation | go_router | 13.0+ |
| Backend SDK | supabase_flutter | 2.0+ |
| Local Database | Drift (SQLite) | 2.14+ |
| HTTP Client | Dio | 5.4+ |
| Voice Input | speech_to_text | 6.6+ |
| Data Classes | Freezed | 2.4+ |
| JSON | json_serializable | 6.7+ |

---

## 2. Flutter Project Structure

### 2.1 Directory Organization

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # Root App widget
│
├── core/                        # Core functionality
│   ├── theme/                   # Design system
│   │   ├── app_theme.dart      # ThemeData configuration
│   │   ├── colors.dart         # Color palette
│   │   ├── typography.dart     # Text styles
│   │   ├── spacing.dart        # Spacing constants
│   │   └── shadows.dart        # Shadow definitions
│   ├── config/
│   │   ├── app_config.dart     # Environment config
│   │   └── supabase_config.dart # Supabase initialization
│   ├── constants/
│   │   ├── api_constants.dart
│   │   └── app_constants.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   └── helpers.dart
│   └── extensions/
│       ├── context_extensions.dart
│       ├── datetime_extensions.dart
│       └── string_extensions.dart
│
├── features/                    # Feature modules (Clean Architecture)
│   ├── auth/
│   │   ├── data/               # Data layer
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── auth_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/             # Business logic
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       ├── logout_usecase.dart
│   │   │       └── register_usecase.dart
│   │   └── presentation/       # UI layer
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── register_screen.dart
│   │       ├── widgets/
│   │       │   └── auth_form.dart
│   │       └── providers/
│   │           └── auth_provider.dart
│   │
│   ├── trainer_home/           # Trainer dashboard
│   ├── client_management/      # Client CRUD operations
│   ├── active_session/         # Session logging (zero-typing)
│   ├── fitlog_life/           # Client view features
│   ├── academy/               # FitLog Academy
│   └── ai_exercise/           # AI workout generation
│
├── shared/                     # Shared across features
│   ├── widgets/
│   │   ├── buttons/
│   │   │   ├── primary_button.dart
│   │   │   ├── secondary_button.dart
│   │   │   └── icon_button.dart
│   │   ├── inputs/
│   │   │   ├── text_field.dart
│   │   │   └── voice_input.dart
│   │   ├── cards/
│   │   │   ├── client_card.dart
│   │   │   └── session_card.dart
│   │   ├── dialogs/
│   │   │   └── confirm_dialog.dart
│   │   └── common/
│   │       ├── loading_indicator.dart
│   │       └── error_widget.dart
│   ├── models/
│   │   └── result.dart         # Result<T, E> for error handling
│   └── services/
│       ├── analytics_service.dart
│       └── notification_service.dart
│
├── navigation/
│   ├── app_router.dart         # go_router configuration
│   └── routes.dart             # Route definitions
│
└── providers/                   # Global Riverpod providers
    ├── supabase_provider.dart
    └── drift_provider.dart
```

### 2.2 Naming Conventions

**Files:**
- `snake_case.dart` for all Dart files
- `*_screen.dart` for full screens
- `*_widget.dart` for reusable widgets
- `*_provider.dart` for Riverpod providers
- `*_model.dart` for data models (Freezed)
- `*_entity.dart` for domain entities

**Classes:**
- `PascalCase` for classes, enums
- `SCREAMING_SNAKE_CASE` for constants
- `camelCase` for variables, functions
- `_privateWithUnderscore` for private members

---

## 3. State Management Architecture

### 3.1 Riverpod Provider Types

**Provider Selection Guide:**

| Provider Type | Use Case | Example |
|--------------|----------|---------|
| `Provider` | Stateless, immutable values | Config, constants |
| `StateProvider` | Simple mutable state | UI toggles, counters |
| `StateNotifierProvider` | Complex state with logic | Auth state, session state |
| `FutureProvider` | Async data loading | API calls, DB queries |
| `StreamProvider` | Real-time data | Supabase Realtime |

### 3.2 Provider Organization

```dart
// lib/features/auth/presentation/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';

part 'auth_provider.freezed.dart';

// State definition with Freezed
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(UserEntity user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
}

// StateNotifier
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        super(const AuthState.initial());

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();

    final result = await _loginUseCase.call(
      LoginParams(email: email, password: password),
    );

    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (user) => state = AuthState.authenticated(user),
    );
  }

  Future<void> logout() async {
    await _logoutUseCase.call();
    state = const AuthState.unauthenticated();
  }
}

// Provider declaration
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.read(loginUseCaseProvider),
    logoutUseCase: ref.read(logoutUseCaseProvider),
  );
});
```

### 3.3 Consuming Providers in UI

```dart
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      initial: () => const LoginForm(),
      loading: () => const LoadingIndicator(),
      authenticated: (user) {
        // Navigate to appropriate view based on role
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (user.role == UserRole.trainer) {
            context.go('/trainer/home');
          } else {
            context.go('/client/today');
          }
        });
        return const SizedBox.shrink();
      },
      unauthenticated: () => const LoginForm(),
      error: (message) => ErrorWidget(message: message),
    );
  }
}
```

---

## 4. Clean Architecture Implementation

### 4.1 Layer Responsibilities

**Data Layer (`lib/features/*/data/`):**
- API calls, database queries
- Data transformation (JSON ↔ Models)
- Caching logic
- Repository implementations

**Domain Layer (`lib/features/*/domain/`):**
- Business entities (pure Dart classes)
- Repository contracts (abstract classes)
- Use cases (business logic)
- Domain-specific errors

**Presentation Layer (`lib/features/*/presentation/`):**
- UI screens and widgets
- State management (Riverpod providers)
- User input handling
- Navigation

### 4.2 Data Flow Example

```
User Action → Provider → UseCase → Repository → DataSource → Supabase
           ←           ←          ←            ←            ←
          UI Update   State     Entity      Model        JSON
```

### 4.3 Repository Pattern

```dart
// Domain layer - Contract
abstract class ClientRepository {
  Future<Either<Failure, List<ClientEntity>>> getClients();
  Future<Either<Failure, ClientEntity>> getClientById(String id);
  Future<Either<Failure, void>> createClient(ClientEntity client);
}

// Data layer - Implementation
class ClientRepositoryImpl implements ClientRepository {
  final ClientRemoteDataSource remoteDataSource;
  final ClientLocalDataSource localDataSource;

  ClientRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<ClientEntity>>> getClients() async {
    try {
      // Try remote first
      final clients = await remoteDataSource.getClients();

      // Cache locally
      await localDataSource.cacheClients(clients);

      return Right(clients.map((m) => m.toEntity()).toList());
    } on NetworkException {
      // Fallback to local cache (offline-first)
      try {
        final cachedClients = await localDataSource.getCachedClients();
        return Right(cachedClients.map((m) => m.toEntity()).toList());
      } catch (e) {
        return Left(CacheFailure());
      }
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
```

---

## 5. Supabase Integration

### 5.1 Initialization

```dart
// lib/core/config/supabase_config.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY',
  );

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }
}

// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  runApp(const ProviderScope(child: FitLogApp()));
}
```

### 5.2 Authentication

```dart
// lib/features/auth/data/datasources/auth_remote_datasource.dart

class AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSource(this._client);

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthException('Login failed');
      }

      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      return data.session != null
          ? AuthState.authenticated(
              UserModel.fromSupabaseUser(data.session!.user),
            )
          : const AuthState.unauthenticated();
    });
  }
}
```

### 5.3 Database Queries with RLS

```dart
// lib/features/client_management/data/datasources/client_remote_datasource.dart

class ClientRemoteDataSource {
  final SupabaseClient _client;

  ClientRemoteDataSource(this._client);

  Future<List<ClientModel>> getClients() async {
    try {
      final response = await _client
          .from('clients')
          .select()
          .eq('trainer_id', _client.auth.currentUser!.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ClientModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> createClient(ClientModel client) async {
    await _client.from('clients').insert(client.toJson());
  }
}
```

### 5.4 Real-time Subscriptions

```dart
// Real-time updates for active session
Stream<SessionModel?> watchActiveSession(String clientId) {
  return _client
      .from('sessions')
      .stream(primaryKey: ['id'])
      .eq('client_id', clientId)
      .eq('status', 'active')
      .map((data) => data.isEmpty
          ? null
          : SessionModel.fromJson(data.first));
}
```

### 5.5 Storage (Body Photos, Media)

```dart
// lib/shared/services/storage_service.dart

class StorageService {
  final SupabaseClient _client;

  StorageService(this._client);

  Future<String> uploadBodyPhoto(String clientId, File photo) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'body_photos/$clientId/$fileName';

    await _client.storage
        .from('media')
        .upload(path, photo);

    return _client.storage
        .from('media')
        .getPublicUrl(path);
  }
}
```

---

## 6. Offline-First Strategy

### 6.1 Drift (SQLite) Setup

```dart
// lib/core/database/app_database.dart

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text()();
  TextColumn get status => text()();
  DateTimeColumn get startedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Clients, Sessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'fitlog_db');
  }
}
```

### 6.2 Offline-First Repository Pattern

```dart
class ClientRepositoryImpl implements ClientRepository {
  @override
  Future<Either<Failure, List<ClientEntity>>> getClients() async {
    try {
      // Always try to fetch from remote first
      final remoteClients = await _remoteDataSource.getClients();

      // Update local cache
      await _localDataSource.cacheClients(remoteClients);

      return Right(remoteClients.map((m) => m.toEntity()).toList());
    } on NetworkException {
      // Network failed - use local cache
      try {
        final cachedClients = await _localDataSource.getCachedClients();
        return Right(cachedClients.map((m) => m.toEntity()).toList());
      } catch (e) {
        return Left(CacheFailure());
      }
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> createClient(ClientEntity client) async {
    try {
      // Save to local first (optimistic UI)
      await _localDataSource.insertClient(ClientModel.fromEntity(client));

      // Then sync to remote
      await _remoteDataSource.createClient(ClientModel.fromEntity(client));

      return const Right(null);
    } catch (e) {
      // Mark for background sync if network fails
      await _syncQueue.add(SyncOperation.createClient(client));
      return const Right(null); // Optimistic success
    }
  }
}
```

### 6.3 Background Sync

```dart
// lib/core/sync/sync_manager.dart

class SyncManager {
  final AppDatabase _db;
  final SupabaseClient _client;

  Future<void> syncPendingOperations() async {
    final pendingOps = await _db.getPendingSync();

    for (final op in pendingOps) {
      try {
        switch (op.type) {
          case SyncType.createClient:
            await _client.from('clients').insert(op.data);
            break;
          case SyncType.updateSession:
            await _client.from('sessions').update(op.data).eq('id', op.id);
            break;
        }

        await _db.markSyncComplete(op.id);
      } catch (e) {
        // Retry later
        continue;
      }
    }
  }
}
```

---

## 7. UI/UX Implementation

### 7.1 Design System (Theme)

```dart
// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surfaceLight,
      ),
      textTheme: AppTypography.textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        contentPadding: EdgeInsets.all(AppSpacing.md),
      ),
    );
  }
}
```

### 7.2 Zero-Typing Interface Components

```dart
// lib/shared/widgets/inputs/voice_input_button.dart

class VoiceInputButton extends ConsumerStatefulWidget {
  final Function(String) onResult;

  const VoiceInputButton({required this.onResult, super.key});

  @override
  ConsumerState<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends ConsumerState<VoiceInputButton> {
  final _speech = SpeechToText();
  bool _isListening = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _startListening,
      onLongPressUp: _stopListening,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isListening ? AppColors.primary : AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _startListening() async {
    await _speech.initialize();

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          widget.onResult(result.recognizedWords);
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }
}
```

### 7.3 Quick-Tap Exercise Selection

```dart
// lib/features/active_session/presentation/widgets/exercise_quick_select.dart

class ExerciseQuickSelect extends StatelessWidget {
  final List<ExerciseEntity> exercises;
  final Function(ExerciseEntity) onSelect;

  const ExerciseQuickSelect({
    required this.exercises,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onSelect(exercise);
          },
          child: Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(exercise.icon, size: 32),
                const SizedBox(height: 4),
                Text(
                  exercise.name,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

## 8. Testing Strategy

### 8.1 Test Structure

```
test/
├── unit/                        # Pure Dart logic tests
│   ├── core/
│   │   └── utils/
│   ├── features/
│   │   └── auth/
│   │       ├── domain/
│   │       │   └── usecases/
│   │       └── data/
│   │           └── repositories/
│   └── shared/
│
├── widget/                      # Widget/UI tests
│   ├── shared/
│   │   └── widgets/
│   └── features/
│       └── auth/
│           └── presentation/
│
└── integration/                 # E2E tests
    ├── auth_flow_test.dart
    └── session_logging_test.dart
```

### 8.2 Unit Test Example

```dart
// test/unit/features/auth/domain/usecases/login_usecase_test.dart

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  group('LoginUseCase', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    final testUser = UserEntity(
      id: '123',
      email: testEmail,
      role: UserRole.trainer,
    );

    test('should return UserEntity when login succeeds', () async {
      // Arrange
      when(mockRepository.login(testEmail, testPassword))
          .thenAnswer((_) async => Right(testUser));

      // Act
      final result = await useCase.call(
        LoginParams(email: testEmail, password: testPassword),
      );

      // Assert
      expect(result, Right(testUser));
      verify(mockRepository.login(testEmail, testPassword));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return AuthFailure when credentials are invalid', () async {
      // Arrange
      when(mockRepository.login(testEmail, testPassword))
          .thenAnswer((_) async => Left(AuthFailure('Invalid credentials')));

      // Act
      final result = await useCase.call(
        LoginParams(email: testEmail, password: testPassword),
      );

      // Assert
      expect(result, Left(AuthFailure('Invalid credentials')));
    });
  });
}
```

### 8.3 Widget Test Example

```dart
// test/widget/shared/widgets/buttons/primary_button_test.dart

void main() {
  testWidgets('PrimaryButton displays text and responds to tap',
      (tester) async {
    bool wasTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Test Button',
            onPressed: () => wasTapped = true,
          ),
        ),
      ),
    );

    // Find button by text
    expect(find.text('Test Button'), findsOneWidget);

    // Tap button
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();

    // Verify callback
    expect(wasTapped, true);
  });
}
```

### 8.4 Integration Test Example

```dart
// integration_test/auth_flow_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete authentication flow', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitLogApp()));

    // Should start at login screen
    expect(find.text('Login'), findsOneWidget);

    // Enter credentials
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'trainer@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'password123',
    );

    // Tap login
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Should navigate to trainer home
    expect(find.text('Trainer Dashboard'), findsOneWidget);
  });
}
```

---

## 9. Performance Optimization

### 9.1 Image Optimization

```dart
// Use cached_network_image for profile photos, body photos
CachedNetworkImage(
  imageUrl: client.profilePhotoUrl,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  memCacheWidth: 200, // Resize in memory
  memCacheHeight: 200,
)
```

### 9.2 List Performance

```dart
// Use ListView.builder for long lists
ListView.builder(
  itemCount: clients.length,
  itemBuilder: (context, index) {
    final client = clients[index];
    return ClientCard(client: client);
  },
)

// Use const constructors where possible
class ClientCard extends StatelessWidget {
  final ClientEntity client;

  const ClientCard({required this.client, super.key});

  // ...
}
```

### 9.3 Lazy Loading

```dart
// Load data on demand
final clientsProvider = FutureProvider.autoDispose<List<ClientEntity>>((ref) async {
  final repository = ref.read(clientRepositoryProvider);
  return repository.getClients();
});
```

---

## 10. Build & Deployment

### 10.1 Build Commands

```bash
# Development build
flutter run --debug

# Profile build (performance testing)
flutter run --profile

# Release build
flutter build apk --release  # Android
flutter build ipa --release  # iOS
```

### 10.2 Environment Configuration

```dart
// Run with environment variables
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=your-anon-key \
            --dart-define=ENVIRONMENT=production
```

### 10.3 Code Generation

```bash
# Generate Freezed, JSON serialization
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode during development
flutter pub run build_runner watch
```

### 10.4 CI/CD (GitHub Actions)

See `.github/workflows/ci.yml` for Flutter-specific CI/CD pipeline.

---

## Next Steps

1. **Set up project structure** following Section 2
2. **Initialize Supabase** following Section 5.1
3. **Implement authentication** following Section 5.2
4. **Build design system** following Section 7.1
5. **Create first feature module** (auth) following Section 4

## References

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Supabase Flutter Guide](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture-tdd/)
