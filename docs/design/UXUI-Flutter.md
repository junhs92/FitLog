# FitLog Pro - Flutter UI/UX Implementation Guide

**Version:** 1.1
**Last Updated:** December 2024 (Session Input Widgets updated)
**Parent Document:** UXUI.md v1.0
**Purpose:** Flutter-specific widget specifications and design system implementation

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Design System in Flutter](#2-design-system-in-flutter)
3. [Core Widget Library](#3-core-widget-library)
4. [Screen Implementations](#4-screen-implementations)
5. [Zero-Typing Interface](#5-zero-typing-interface)
6. [Animations & Transitions](#6-animations--transitions)
7. [Accessibility](#7-accessibility)
8. [Responsive Design](#8-responsive-design)

---

## 1. Introduction

### 1.1 Purpose

This document translates the React Native UI specifications from UXUI.md into Flutter widget implementations, providing developers with ready-to-use code patterns and design system guidelines.

### 1.2 Design Philosophy

From PRD.md:
- **Zero-Typing Interface:** <60 seconds to log a complete session
- **AI-First:** LLM-powered summaries and recommendations
- **Trainer-Centric:** Built for gym floor, one-handed operation
- **Offline-First:** Core features work without connectivity

---

## 2. Design System in Flutter

### 2.1 Color Palette

```dart
// lib/core/theme/colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF4C6EF5);        // Blue
  static const Color primaryLight = Color(0xFF748FFC);
  static const Color primaryDark = Color(0xFF3B5BDB);

  // Secondary Colors
  static const Color secondary = Color(0xFF20C997);      // Teal
  static const Color secondaryLight = Color(0xFF51CF66);
  static const Color secondaryDark = Color(0xFF099268);

  // Neutral Colors
  static const Color neutralBlack = Color(0xFF1A1B1E);
  static const Color neutral900 = Color(0xFF2C2E33);
  static const Color neutral800 = Color(0xFF373A40);
  static const Color neutral700 = Color(0xFF909296);
  static const Color neutral500 = Color(0xFFADB5BD);
  static const Color neutral300 = Color(0xFFDEE2E6);
  static const Color neutral100 = Color(0xFFF1F3F5);
  static const Color neutralWhite = Color(0xFFFFFFFF);

  // Semantic Colors
  static const Color success = Color(0xFF51CF66);
  static const Color warning = Color(0xFFFCC419);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF4DABF7);

  // Surface Colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1B1E);
  static const Color surfaceElevated = Color(0xFFF8F9FA);

  // Overlay
  static const Color overlayDark = Color(0x99000000);    // 60% opacity
  static const Color overlayLight = Color(0x33000000);   // 20% opacity
}
```

### 2.2 Typography

```dart
// lib/core/theme/typography.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  AppTypography._();

  // Base font family
  static const String fontFamily = 'Inter';

  // Text Theme
  static TextTheme get textTheme => TextTheme(
        // Display styles (large headings)
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.5,
          color: AppColors.neutralBlack,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.3,
          letterSpacing: -0.3,
          color: AppColors.neutralBlack,
        ),

        // Headline styles
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: AppColors.neutralBlack,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: AppColors.neutralBlack,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: AppColors.neutralBlack,
        ),

        // Title styles
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: AppColors.neutralBlack,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: AppColors.neutralBlack,
        ),

        // Body styles
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: AppColors.neutral900,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: AppColors.neutral900,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: AppColors.neutral700,
        ),

        // Label styles
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.5,
          letterSpacing: 0.1,
          color: AppColors.neutral900,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.5,
          letterSpacing: 0.1,
          color: AppColors.neutral700,
        ),
      );
}
```

### 2.3 Spacing

```dart
// lib/core/theme/spacing.dart

class AppSpacing {
  AppSpacing._();

  // Base spacing unit: 4px
  static const double unit = 4.0;

  // Spacing scale
  static const double xs = unit;         // 4px
  static const double sm = unit * 2;     // 8px
  static const double md = unit * 3;     // 12px
  static const double lg = unit * 4;     // 16px
  static const double xl = unit * 6;     // 24px
  static const double xxl = unit * 8;    // 32px
  static const double xxxl = unit * 12;  // 48px

  // Border radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusFull = 999.0;

  // Component-specific spacing
  static const double cardPadding = lg;
  static const double screenPadding = lg;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 48.0;
}
```

### 2.4 Shadows

```dart
// lib/core/theme/shadows.dart

import 'package:flutter/material.dart';
import 'colors.dart';

class AppShadows {
  AppShadows._();

  // Shadow levels
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: AppColors.neutralBlack.withOpacity(0.05),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: AppColors.neutralBlack.withOpacity(0.1),
          offset: const Offset(0, 4),
          blurRadius: 6,
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: AppColors.neutralBlack.withOpacity(0.1),
          offset: const Offset(0, 10),
          blurRadius: 15,
        ),
      ];

  static List<BoxShadow> get xl => [
        BoxShadow(
          color: AppColors.neutralBlack.withOpacity(0.15),
          offset: const Offset(0, 20),
          blurRadius: 25,
        ),
      ];
}
```

### 2.5 App Theme

```dart
// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.neutralWhite,
        secondary: AppColors.secondary,
        onSecondary: AppColors.neutralWhite,
        error: AppColors.error,
        onError: AppColors.neutralWhite,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.neutralBlack,
      ),

      // Typography
      textTheme: AppTypography.textTheme,
      fontFamily: AppTypography.fontFamily,

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.neutralBlack,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme.headlineMedium,
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.neutralWhite,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          elevation: 0,
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral100,
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.textTheme.bodyMedium,
        hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.neutral500,
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: AppColors.neutral300, width: 1),
        ),
        margin: const EdgeInsets.all(0),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.neutral300,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
```

---

## 3. Core Widget Library

### 3.1 Primary Button

```dart
// lib/shared/widgets/buttons/primary_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/spacing.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const PrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handlePress,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }

  void _handlePress() {
    HapticFeedback.lightImpact();
    onPressed?.call();
  }
}
```

### 3.2 Voice Input Button

```dart
// lib/shared/widgets/inputs/voice_input_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

class VoiceInputButton extends StatefulWidget {
  final Function(String) onResult;
  final String? hint;

  const VoiceInputButton({
    required this.onResult,
    this.hint,
    super.key,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _startListening,
      onLongPressEnd: (_) => _stopListening(),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _isListening ? AppColors.primary : AppColors.neutral300,
              shape: BoxShape.circle,
              boxShadow: _isListening
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 20 * (1 + _pulseController.value),
                        spreadRadius: 5 * _pulseController.value,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.white : AppColors.neutral700,
              size: 32,
            ),
          );
        },
      ),
    );
  }

  Future<void> _startListening() async {
    HapticFeedback.mediumImpact();

    setState(() => _isListening = true);
    _pulseController.repeat(reverse: true);

    await _speech.listen(
      onResult: (result) {
        setState(() => _recognizedText = result.recognizedWords);

        if (result.finalResult) {
          widget.onResult(result.recognizedWords);
          _stopListening();
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  Future<void> _stopListening() async {
    HapticFeedback.lightImpact();

    await _speech.stop();
    _pulseController.stop();

    setState(() => _isListening = false);

    if (_recognizedText.isNotEmpty) {
      widget.onResult(_recognizedText);
      _recognizedText = '';
    }
  }
}
```

### 3.3 Client Card

```dart
// lib/shared/widgets/cards/client_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../features/client_management/domain/entities/client_entity.dart';

class ClientCard extends StatelessWidget {
  final ClientEntity client;
  final VoidCallback? onTap;

  const ClientCard({
    required this.client,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Profile Photo
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.neutral300,
                backgroundImage: client.profilePhotoUrl != null
                    ? CachedNetworkImageProvider(client.profilePhotoUrl!)
                    : null,
                child: client.profilePhotoUrl == null
                    ? Text(
                        client.name.substring(0, 1).toUpperCase(),
                        style: AppTypography.textTheme.headlineMedium,
                      )
                    : null,
              ),

              const SizedBox(width: AppSpacing.md),

              // Client Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: AppTypography.textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${client.totalSessions} sessions',
                      style: AppTypography.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Status Indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    final daysSinceLastSession =
        DateTime.now().difference(client.lastSessionDate).inDays;

    if (daysSinceLastSession <= 3) {
      return AppColors.success;
    } else if (daysSinceLastSession <= 7) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }
}
```

### 3.4 Quick Tap Exercise Selector

```dart
// lib/features/active_session/presentation/widgets/exercise_quick_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/entities/exercise_entity.dart';

class ExerciseQuickSelector extends StatelessWidget {
  final List<ExerciseEntity> exercises;
  final Function(ExerciseEntity) onSelect;

  const ExerciseQuickSelector({
    required this.exercises,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: exercises.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _ExerciseTile(
          exercise: exercise,
          onTap: () {
            HapticFeedback.lightImpact();
            onSelect(exercise);
          },
        );
      },
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final ExerciseEntity exercise;
  final VoidCallback onTap;

  const _ExerciseTile({
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getExerciseIcon(exercise.category),
                size: 32,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                exercise.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getExerciseIcon(String category) {
    switch (category.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.rowing;
      case 'legs':
        return Icons.directions_walk;
      case 'shoulders':
        return Icons.accessibility_new;
      case 'arms':
        return Icons.pan_tool;
      case 'core':
        return Icons.center_focus_strong;
      default:
        return Icons.fitness_center;
    }
  }
}
```

---

## 4. Screen Implementations

### 4.1 Login Screen

```dart
// lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      next.maybeWhen(
        authenticated: (user) {
          // Navigate based on role
          if (user.role == UserRole.trainer) {
            context.go('/trainer/home');
          } else {
            context.go('/client/today');
          }
        },
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
        orElse: () {},
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Icon(
                  Icons.fitness_center,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Title
                Text(
                  'Welcome to FitLog Pro',
                  style: AppTypography.textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'trainer@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: '••••••••',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // Login Button
                authState.maybeWhen(
                  loading: () => const PrimaryButton(
                    label: 'Logging in...',
                    isLoading: true,
                  ),
                  orElse: () => PrimaryButton(
                    label: 'Login',
                    onPressed: _handleLogin,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Register Link
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Don\'t have an account? Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }
}
```

### 4.2 Active Session Screen

```dart
// lib/features/active_session/presentation/screens/active_session_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/inputs/voice_input_button.dart';
import '../widgets/exercise_quick_selector.dart';
import '../providers/session_provider.dart';

class ActiveSessionScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ActiveSessionScreen({
    required this.clientId,
    super.key,
  });

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show session options
            },
          ),
        ],
      ),
      body: sessionState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error) => Center(child: Text('Error: $error')),
        data: (session) => Column(
          children: [
            // Session Timer
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Time',
                        style: AppTypography.textTheme.bodySmall,
                      ),
                      Text(
                        _formatDuration(session.duration),
                        style: AppTypography.textTheme.displayMedium,
                      ),
                    ],
                  ),
                  Text(
                    '${session.exercises.length} exercises',
                    style: AppTypography.textTheme.titleMedium,
                  ),
                ],
              ),
            ),

            // Exercise List
            Expanded(
              child: session.exercises.isEmpty
                  ? _buildEmptyState()
                  : _buildExerciseList(session.exercises),
            ),

            // Bottom Actions
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 64),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No exercises logged yet',
            style: AppTypography.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap exercises below or use voice input',
            style: AppTypography.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(List<Exercise> exercises) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: exercises.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(exercise.name),
            subtitle: Text('${exercise.sets} sets × ${exercise.reps} reps'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Edit exercise
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice Input
          Center(
            child: VoiceInputButton(
              onResult: (text) {
                ref.read(sessionProvider.notifier).addExerciseFromVoice(text);
              },
              hint: 'Hold to speak exercise',
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Quick Exercise Selector
          const Text(
            'Or tap to select:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: AppSpacing.sm),

          ExerciseQuickSelector(
            exercises: _getQuickExercises(),
            onSelect: (exercise) {
              ref.read(sessionProvider.notifier).addExercise(exercise);
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Complete Session Button
          PrimaryButton(
            label: 'Complete Session',
            icon: Icons.check,
            onPressed: () {
              _showCompleteDialog();
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  List<ExerciseEntity> _getQuickExercises() {
    // Return frequently used exercises
    return [];
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Session?'),
        content: const Text(
          'Are you sure you want to complete this session? '
          'You can add notes and generate an AI summary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(sessionProvider.notifier).completeSession();
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Zero-Typing Interface

### 5.0 Session Input Widgets

The active session screen uses specialized zero-typing input widgets for rapid data entry during workouts.

#### 5.0.1 Weight Adjuster

**File:** `lib/features/active_session/presentation/widgets/weight_adjuster.dart`

**Layout:**
```
        [ - ]  [ 45 kg ]  [ + ]     ← ±0.5kg fine adjustment
    [ -10 ] [ -5 ] [-2.5]  [+2.5] [ +5 ] [+10]  ← Quick adjustment buttons
```

**Features:**
- Central weight display (48px bold font)
- Circular -, + buttons for 0.5kg increments (fine tuning)
- Quick adjustment row: -10, -5, -2.5, +2.5, +5, +10 kg
- Red color for decrement, green for increment
- Haptic feedback on all interactions
- Clamped to 0-500kg range

#### 5.0.2 Rep Selector

**File:** `lib/features/active_session/presentation/widgets/rep_selector.dart`

**Layout:**
```
        [ - ]  [ 12 reps ]  [ + ]
    [ 3 ] [ 5 ] [ 8 ] [ 12 ] [ 15 ] [ 20 ]   ← Preset buttons
```

**Features:**
- Central reps display (48px bold font)
- Circular -, + buttons for single rep adjustment
- Preset buttons: 3, 5, 8, 12, 15, 20 reps
- Selected preset highlighted with primary color
- Haptic feedback on all interactions
- Clamped to 1-30 reps range

#### 5.0.3 RPE Slider

**File:** `lib/features/active_session/presentation/widgets/rpe_slider.dart`

**Layout:**
```
    [ - ]  [ 😤 RPE 8 Hard ]  [ + ]    ← -, + works 1-10 range
         [ 4 ] [ 5 ] [ 6 ] [ 7 ] [ 8 ] [ 9 ]   ← Selector shows 4-9
         Easy                           Max
```

**Features:**
- Current RPE display with emoji and description
- Circular -, + buttons navigate full 1-10 range
- Preset selector buttons show common range 4-9
- Color-coded by difficulty:
  - Green (1-6): Easy to Moderate
  - Secondary (7): Challenging
  - Orange (8): Hard
  - Red (9-10): Very Hard to Maximum
- RPE descriptions and emojis for all values 1-10
- Haptic feedback on all interactions

**RPE Scale:**
| RPE | Emoji | Description |
|-----|-------|-------------|
| 1   | 😴    | Very Light  |
| 2   | 😌    | Light       |
| 3   | 🙂    | Light+      |
| 4   | 😊    | Fairly Light|
| 5   | 😊    | Easy        |
| 6   | 🙂    | Moderate    |
| 7   | 😐    | Challenging |
| 8   | 😤    | Hard        |
| 9   | 😰    | Very Hard   |
| 10  | 💀    | Maximum     |

#### 5.0.4 Session Sets History

**File:** `lib/features/active_session/presentation/screens/active_session_screen.dart`

**Layout:**
```
┌─────────────────────────────────────────────────────┐
│ 📜 Session History                         3 sets   │
├─────────────────────────────────────────────────────┤
│  #  │ Exercise        │ Weight │ Reps │ RPE        │
├─────────────────────────────────────────────────────┤
│ (1) │ Bench Press     │   60   │  12  │  7         │
│ (2) │ Squat           │   80   │   8  │  8         │
│ (3) │ Bench Press     │   65   │  10  │  8         │
└─────────────────────────────────────────────────────┘

                    Current Exercise
                    ────────────────
```

**Features:**
- Unified history of ALL sets across ALL exercises
- Displayed above the current exercise name
- Sets ordered by completion timestamp (`completedAt`)
- Shows: set number, exercise name, weight, reps, RPE
- Warmup sets show "W" with blue highlight
- PR sets show gold/warning highlight
- RPE color-coded by difficulty
- Header shows total set count
- Hidden when no sets logged yet
- Maintains chronological order even when exercises are swapped mid-session

#### 5.0.5 Set Completion Flow

When trainer taps "Set complete":
1. **Scroll to top** - Smooth animation (300ms) to top of screen
2. **Start rest timer** - Automatic countdown begins
3. **Show rest overlay** - Bottom sheet with timer controls

### 5.1 Voice Input Implementation

**Speech Recognition Setup:**
```yaml
# pubspec.yaml
dependencies:
  speech_to_text: ^6.6.0
  permission_handler: ^11.0.1
```

**Permissions:**
```xml
<!-- Android: android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />

<!-- iOS: ios/Runner/Info.plist -->
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice input during workouts</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We use speech recognition to log exercises hands-free</string>
```

### 5.2 Haptic Feedback

```dart
// lib/core/utils/haptics.dart

import 'package:flutter/services.dart';

class HapticsUtil {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void selection() => HapticFeedback.selectionClick();
}
```

---

## 6. Animations & Transitions

### 6.1 Page Transitions

```dart
// lib/navigation/app_router.dart

GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
  ],
);
```

### 6.2 Loading States

```dart
// lib/shared/widgets/common/loading_indicator.dart

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(message!, style: AppTypography.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
```

---

## 7. Accessibility

### 7.1 Semantic Labels

```dart
Semantics(
  label: 'Voice input button. Hold to speak exercise details',
  button: true,
  child: VoiceInputButton(onResult: _handleVoiceInput),
)
```

### 7.2 Text Scaling

All text widgets use theme text styles which automatically support user font size preferences.

### 7.3 Color Contrast

All color combinations meet WCAG AA standards (4.5:1 contrast ratio minimum).

---

## 8. Responsive Design

### 8.1 Breakpoints

```dart
// lib/core/utils/responsive.dart

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static double padding(BuildContext context) =>
      isMobile(context) ? AppSpacing.lg : AppSpacing.xl;
}
```

---

## Next Steps

1. **Implement design system** (Section 2)
2. **Build core widgets** (Section 3)
3. **Create authentication screens** (Section 4.1)
4. **Implement session logging** (Section 4.2)
5. **Add voice input** (Section 5)

## References

- [Flutter Material 3](https://m3.material.io/develop/flutter)
- [Google Fonts Package](https://pub.dev/packages/google_fonts)
- [Speech to Text Package](https://pub.dev/packages/speech_to_text)
- [Go Router](https://pub.dev/packages/go_router)
