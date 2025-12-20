import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/rest_timer_service.dart';

/// Provider for rest timer state
final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});

/// Notifier for managing rest timer state
class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;

  // Haptic feedback intervals
  static const int _hapticWarning1 = 10;
  static const int _hapticWarning2 = 5;

  RestTimerNotifier() : super(const RestTimerState());

  /// Start the timer with specified duration
  void startTimer({int? seconds}) {
    final duration = seconds ?? state.totalSeconds;

    _timer?.cancel();
    state = state.copyWith(
      totalSeconds: duration,
      remainingSeconds: duration,
      isRunning: true,
      isPaused: false,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  /// Start timer with a preset duration
  void startWithPreset(int presetSeconds) {
    startTimer(seconds: presetSeconds);
  }

  /// Pause the timer
  void pauseTimer() {
    if (!state.isRunning) return;

    _timer?.cancel();
    state = state.copyWith(
      isRunning: false,
      isPaused: true,
    );
  }

  /// Resume paused timer
  void resumeTimer() {
    if (!state.isPaused || state.remainingSeconds <= 0) return;

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  /// Skip the timer (complete immediately)
  void skipTimer() {
    _timer?.cancel();
    state = state.copyWith(
      remainingSeconds: 0,
      isRunning: false,
      isPaused: false,
    );
  }

  /// Reset timer to initial duration
  void resetTimer() {
    _timer?.cancel();
    state = state.copyWith(
      remainingSeconds: state.totalSeconds,
      isRunning: false,
      isPaused: false,
    );
  }

  /// Add time to current timer
  void addTime(int seconds) {
    final newRemaining = state.remainingSeconds + seconds;
    final newTotal =
        newRemaining > state.totalSeconds ? newRemaining : state.totalSeconds;

    state = state.copyWith(
      remainingSeconds: newRemaining,
      totalSeconds: newTotal,
    );
  }

  /// Set default duration for future timers
  void setDefaultDuration(int seconds) {
    state = state.copyWith(totalSeconds: seconds);
  }

  /// Toggle auto-start setting
  void toggleAutoStart() {
    state = state.copyWith(autoStart: !state.autoStart);
  }

  /// Set auto-start setting
  void setAutoStart(bool value) {
    state = state.copyWith(autoStart: value);
  }

  /// Called when a set is logged - auto-starts timer if enabled
  void onSetLogged() {
    if (state.autoStart) {
      startTimer();
    }
  }

  void _onTick(Timer timer) {
    if (state.remainingSeconds > 0) {
      final newRemaining = state.remainingSeconds - 1;

      // Haptic feedback at warning intervals
      if (newRemaining == _hapticWarning1 || newRemaining == _hapticWarning2) {
        HapticFeedback.mediumImpact();
      }

      // Final countdown (last 3 seconds)
      if (newRemaining <= 3 && newRemaining > 0) {
        HapticFeedback.lightImpact();
      }

      state = state.copyWith(remainingSeconds: newRemaining);
    } else {
      // Timer complete
      _timer?.cancel();
      HapticFeedback.heavyImpact();
      state = state.copyWith(
        remainingSeconds: 0,
        isRunning: false,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
