# Contributing to FitLog Pro

Thank you for your interest in contributing to FitLog Pro! This document provides guidelines and best practices for contributing to the project.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Style](#code-style)
- [Project Structure](#project-structure)
- [State Management](#state-management)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Commit Messages](#commit-messages)

---

## 📜 Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Maintain professional communication

---

## 🚀 Getting Started

### 1. Fork & Clone

```bash
git fork https://github.com/your-org/fitlog-pro
git clone https://github.com/YOUR_USERNAME/fitlog-pro.git
cd FitLog_Pro_app
```

### 2. Set Up Development Environment

```bash
# Install dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Verify setup
flutter analyze
flutter test
```

### 3. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

---

## 🔄 Development Workflow

### 1. Make Changes

- Write clean, readable code
- Follow Dart and Flutter best practices
- Use `const` constructors where possible
- Implement proper error handling

### 2. Run Code Generation

When modifying Freezed, JSON serialization, or Riverpod code:

```bash
# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (recommended during development)
flutter pub run build_runner watch
```

### 3. Test Your Changes

```bash
# Run all tests
flutter test

# Run specific tests
flutter test test/unit/features/your_feature/

# Check coverage
flutter test --coverage
```

### 4. Lint Your Code

```bash
flutter analyze
```

Fix all issues before committing. Our `analysis_options.yaml` enforces strict linting rules.

### 5. Format Code

```bash
dart format lib/ test/
```

---

## 🎨 Code Style

### Dart Style Guide

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines:

**Naming Conventions:**
```dart
// Classes, enums, typedefs: PascalCase
class ClientEntity {}
enum UserRole {}

// Libraries, packages, directories, files: snake_case
import 'package:fitlog_pro_app/features/auth/data/models/user_model.dart';

// Variables, constants, parameters, functions: camelCase
final String userName = 'John';
void fetchClients() {}

// Constants: SCREAMING_SNAKE_CASE
const int MAX_RETRY_COUNT = 3;
```

**Prefer Single Quotes:**
```dart
final String message = 'Hello World';  // ✅ Good
final String message = "Hello World";  // ❌ Avoid
```

**Use `const` Constructors:**
```dart
const SizedBox(height: 16)          // ✅ Good
SizedBox(height: 16)                // ❌ Avoid when possible
```

**Prefer Final:**
```dart
final String name = 'John';         // ✅ Good
String name = 'John';               // ❌ Avoid if not reassigned
```

---

## 📂 Project Structure

### Feature Module Organization

Each feature follows Clean Architecture with three layers:

```
lib/features/your_feature/
├── data/
│   ├── datasources/
│   │   ├── feature_remote_datasource.dart
│   │   └── feature_local_datasource.dart
│   ├── models/
│   │   └── feature_model.dart
│   └── repositories/
│       └── feature_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── feature_entity.dart
│   ├── repositories/
│   │   └── feature_repository.dart
│   └── usecases/
│       ├── get_feature_usecase.dart
│       └── create_feature_usecase.dart
└── presentation/
    ├── screens/
    │   └── feature_screen.dart
    ├── widgets/
    │   └── feature_widget.dart
    └── providers/
        └── feature_provider.dart
```

### Layer Responsibilities

**Data Layer:**
- API calls and database queries
- Data transformation (JSON ↔ Models)
- Repository implementations

**Domain Layer:**
- Business entities (pure Dart classes)
- Repository contracts (abstract classes)
- Use cases (single business operations)

**Presentation Layer:**
- UI screens and widgets
- State management (Riverpod providers)
- User input handling

---

## 🔄 State Management

### Riverpod Patterns

**Provider Types:**

```dart
// Immutable values (config, constants)
final configProvider = Provider<AppConfig>((ref) => AppConfig());

// Simple mutable state
final counterProvider = StateProvider<int>((ref) => 0);

// Complex state with logic
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.read(loginUseCaseProvider),
  );
});

// Async data loading
final clientsProvider = FutureProvider<List<ClientEntity>>((ref) async {
  return await ref.read(clientRepositoryProvider).getClients();
});

// Real-time streams
final sessionStreamProvider = StreamProvider<SessionEntity?>((ref) {
  return ref.read(sessionRepositoryProvider).watchActiveSession();
});
```

**StateNotifier Pattern:**

```dart
@freezed
class FeatureState with _$FeatureState {
  const factory FeatureState.initial() = _Initial;
  const factory FeatureState.loading() = _Loading;
  const factory FeatureState.loaded(Data data) = _Loaded;
  const factory FeatureState.error(String message) = _Error;
}

class FeatureNotifier extends StateNotifier<FeatureState> {
  final UseCase _useCase;

  FeatureNotifier(this._useCase) : super(const FeatureState.initial());

  Future<void> fetchData() async {
    state = const FeatureState.loading();

    final result = await _useCase.call();

    result.fold(
      (failure) => state = FeatureState.error(failure.message),
      (data) => state = FeatureState.loaded(data),
    );
  }
}
```

---

## 🧪 Testing

### Test Structure

```
test/
├── unit/              # Pure business logic
│   └── features/
│       └── auth/
│           ├── domain/
│           │   └── usecases/
│           │       └── login_usecase_test.dart
│           └── data/
│               └── repositories/
│                   └── auth_repository_impl_test.dart
├── widget/            # UI component tests
│   └── shared/
│       └── widgets/
│           └── primary_button_test.dart
└── integration/       # End-to-end flows
    └── auth_flow_test.dart
```

### Unit Test Example

```dart
void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  group('LoginUseCase', () {
    test('should return UserEntity when credentials are valid', () async {
      // Arrange
      const testUser = UserEntity(id: '123', email: 'test@example.com');
      when(mockRepository.login(any, any))
          .thenAnswer((_) async => Right(testUser));

      // Act
      final result = await useCase(LoginParams(
        email: 'test@example.com',
        password: 'password123',
      ));

      // Assert
      expect(result, Right(testUser));
      verify(mockRepository.login('test@example.com', 'password123'));
    });
  });
}
```

### Widget Test Example

```dart
void main() {
  testWidgets('PrimaryButton should display label and respond to tap',
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

    expect(find.text('Test Button'), findsOneWidget);

    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();

    expect(wasTapped, true);
  });
}
```

### Test Requirements

- **Unit tests** for all use cases and repositories
- **Widget tests** for custom widgets
- **Integration tests** for critical user flows
- Minimum **80% code coverage** for new features

---

## 📝 Pull Request Process

### 1. Pre-PR Checklist

- [ ] Code follows style guidelines
- [ ] All tests pass (`flutter test`)
- [ ] Linter passes (`flutter analyze`)
- [ ] Code is formatted (`dart format`)
- [ ] No debug prints or commented code
- [ ] Documentation updated if needed

### 2. Create Pull Request

- Use descriptive title: `feat: add voice input to session logging`
- Reference related issues: `Closes #123`
- Provide detailed description
- Include screenshots/videos for UI changes

### 3. PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- Describe testing approach
- List test scenarios covered

## Screenshots (if applicable)
Add screenshots or videos

## Checklist
- [ ] Tests pass
- [ ] Linter passes
- [ ] Code formatted
- [ ] Documentation updated
```

### 4. Code Review

- Address all review comments
- Keep discussions focused and respectful
- Request re-review after changes

---

## 💬 Commit Messages

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, missing semicolons)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes

### Examples

```
feat(auth): add biometric authentication

Implement fingerprint and face ID authentication for iOS and Android
using local_auth package.

Closes #45
```

```
fix(session): resolve null pointer in exercise logging

Fixed crash when logging exercise without previous data.
Added null checks and default values.

Fixes #78
```

---

## 🔒 Security

- Never commit secrets or API keys
- Use environment variables for sensitive data
- Review Supabase RLS policies
- Follow OWASP mobile security guidelines

---

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Riverpod Documentation](https://riverpod.dev/)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture-tdd/)
- [Supabase Flutter Guide](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)

---

## ❓ Questions?

- Open an issue for bugs or feature requests
- Start a discussion for questions or ideas
- Reach out to maintainers for guidance

---

**Thank you for contributing to FitLog Pro!** 🎉
