import 'package:flutter/widgets.dart';

/// When a background transition should lock the vault, and when an activity
/// this app launched must not count as leaving.
///
/// Two different external flows exist:
///
/// * Pickers, the biometric prompt and the Play purchase sheet keep a Dart
///   future alive until the user is back. Holding the guard for that future
///   is enough (`untilResume: false`).
/// * Share, mailto, the Play listing, work-profile settings and similar
///   `startActivity` calls return as soon as Android accepts the intent —
///   often before `paused` is delivered. Those set [untilResume] so the hold
///   lasts until the next [AppLifecycleState.resumed], not until the future
///   ends. The flag is set synchronously before the call is awaited, so a
///   pause queued behind that call still sees it. No timer.
class AutoLockGuard {
  AutoLockGuard({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  DateTime? _backgroundedAt;
  int _depth = 0;
  bool _awaitingReturn = false;
  bool _untilResume = false;
  bool _sawBackground = false;
  bool _sawResume = false;

  /// True while an external activity we started should suppress auto-lock.
  bool get holding => _depth > 0 || _awaitingReturn;

  /// Call synchronously before launching the external UI.
  void begin({bool untilResume = false}) {
    if (_depth == 0) {
      _sawBackground = false;
      _sawResume = false;
      _awaitingReturn = false;
      _untilResume = untilResume;
      _backgroundedAt = null;
    } else if (untilResume) {
      _untilResume = true;
    }
    _depth++;
  }

  /// [staysOut] is true when the platform call returned before the user
  /// came back (and an activity actually started).
  void end({required bool staysOut}) {
    if (_depth > 0) _depth--;
    if (_depth > 0) return;
    final leftAndBack = _sawBackground && _sawResume;
    if (!staysOut || !_untilResume || leftAndBack) {
      _clearHold();
      return;
    }
    // Still in the other activity, or its pause has not been delivered yet.
    _awaitingReturn = true;
  }

  void _clearHold() {
    _awaitingReturn = false;
    _untilResume = false;
    _sawBackground = false;
    _sawResume = false;
    _backgroundedAt = null;
  }

  /// Returns whether the vault should lock for this transition.
  ///
  /// [timeoutSec] `0` locks on leave (Home, recents, screen off). A positive
  /// value locks on the following resume only when at least that many seconds
  /// passed. [AppLifecycleState.inactive] (notification shade, a dialog that
  /// does not pause us) never locks.
  bool onLifecycle(AppLifecycleState state, {required int timeoutSec}) {
    if (_depth > 0) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden) {
        _sawBackground = true;
      } else if (state == AppLifecycleState.resumed) {
        _sawResume = true;
      }
      return state == AppLifecycleState.detached;
    }
    if (_awaitingReturn) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden) {
        _sawBackground = true;
        return false;
      }
      if (state == AppLifecycleState.resumed) {
        _clearHold();
        return false;
      }
      return state == AppLifecycleState.detached;
    }
    final now = _now();
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _backgroundedAt ??= now;
        return timeoutSec <= 0;
      case AppLifecycleState.resumed:
        final since = _backgroundedAt;
        _backgroundedAt = null;
        if (since == null || timeoutSec <= 0) return false;
        return now.difference(since) >= Duration(seconds: timeoutSec);
      case AppLifecycleState.detached:
        return true;
      case AppLifecycleState.inactive:
        return false;
    }
  }
}

/// Whether [result] of a platform call means an activity was started and the
/// future does not wait for the user to come back.
bool externalCallStaysOut(Object? result) {
  if (result == null) return false;
  if (result is bool) return result;
  if (result is String) {
    const failed = {
      'none',
      'unavailable',
      'error',
      'canceled',
      'no_profile',
      'blocked',
    };
    return !failed.contains(result);
  }
  return true;
}
