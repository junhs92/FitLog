import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for managing rest timer between sets
/// Features:
/// - Configurable duration (30s, 60s, 90s, 120s)
/// - Haptic feedback at intervals (10s, 5s remaining)
/// - Audio notification at completion
/// - Auto-start option after logging set
class RestTimerService extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalSeconds = 90;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _autoStart = true;

  // Preset durations in seconds
  static const List<int> presetDurations = [30, 60, 90, 120, 180];
  static const int defaultDuration = 90;

  // Haptic feedback intervals
  static const int _hapticWarning1 = 10; // 10 seconds remaining
  static const int _hapticWarning2 = 5; // 5 seconds remaining

  // Getters
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  bool get autoStart => _autoStart;

  /// Progress value (0.0 to 1.0) for circular indicator
  double get progress =>
      _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;

  /// Formatted time string (MM:SS)
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if timer is complete
  bool get isComplete => _remainingSeconds <= 0 && !_isRunning;

  /// Start the timer with specified duration
  void startTimer({int? seconds}) {
    _totalSeconds = seconds ?? _totalSeconds;
    _remainingSeconds = _totalSeconds;
    _isRunning = true;
    _isPaused = false;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);

    notifyListeners();
  }

  /// Start timer with a preset duration
  void startWithPreset(int presetSeconds) {
    _totalSeconds = presetSeconds;
    startTimer(seconds: presetSeconds);
  }

  /// Pause the timer
  void pauseTimer() {
    if (!_isRunning) return;

    _timer?.cancel();
    _isPaused = true;
    _isRunning = false;

    notifyListeners();
  }

  /// Resume paused timer
  void resumeTimer() {
    if (!_isPaused || _remainingSeconds <= 0) return;

    _isRunning = true;
    _isPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);

    notifyListeners();
  }

  /// Skip the timer (complete immediately)
  void skipTimer() {
    _timer?.cancel();
    _remainingSeconds = 0;
    _isRunning = false;
    _isPaused = false;

    notifyListeners();
  }

  /// Reset timer to initial duration
  void resetTimer() {
    _timer?.cancel();
    _remainingSeconds = _totalSeconds;
    _isRunning = false;
    _isPaused = false;

    notifyListeners();
  }

  /// Add time to current timer
  void addTime(int seconds) {
    _remainingSeconds += seconds;
    if (_remainingSeconds > _totalSeconds) {
      _totalSeconds = _remainingSeconds;
    }
    notifyListeners();
  }

  /// Set default duration for future timers
  void setDefaultDuration(int seconds) {
    _totalSeconds = seconds;
    notifyListeners();
  }

  /// Toggle auto-start setting
  void toggleAutoStart() {
    _autoStart = !_autoStart;
    notifyListeners();
  }

  /// Set auto-start setting
  void setAutoStart(bool value) {
    _autoStart = value;
    notifyListeners();
  }

  /// Called when a set is logged - auto-starts timer if enabled
  void onSetLogged() {
    if (_autoStart) {
      startTimer();
    }
  }

  void _onTick(Timer timer) {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;

      // Haptic feedback at warning intervals
      if (_remainingSeconds == _hapticWarning1 ||
          _remainingSeconds == _hapticWarning2) {
        _triggerHapticWarning();
      }

      // Final countdown (last 3 seconds)
      if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
        _triggerHapticLight();
      }

      notifyListeners();
    } else {
      // Timer complete
      _timer?.cancel();
      _isRunning = false;
      _onTimerComplete();
      notifyListeners();
    }
  }

  void _triggerHapticWarning() {
    HapticFeedback.mediumImpact();
  }

  void _triggerHapticLight() {
    HapticFeedback.lightImpact();
  }

  void _onTimerComplete() {
    // Strong haptic feedback when timer completes
    HapticFeedback.heavyImpact();

    // TODO: Add audio notification
    // This could use a package like audioplayers or just_audio
    // to play a short notification sound
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Rest timer state for use with Riverpod
class RestTimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final bool isPaused;
  final bool autoStart;

  const RestTimerState({
    this.remainingSeconds = 90,
    this.totalSeconds = 90,
    this.isRunning = false,
    this.isPaused = false,
    this.autoStart = true,
  });

  double get progress =>
      totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;

  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isComplete => remainingSeconds <= 0 && !isRunning;

  RestTimerState copyWith({
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    bool? isPaused,
    bool? autoStart,
  }) {
    return RestTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      autoStart: autoStart ?? this.autoStart,
    );
  }
}
