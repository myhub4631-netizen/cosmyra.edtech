import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@JS('window')
external JSObject get _window;

class AudioFeedbackService {
  static const String _prefKey = 'cosmyra_audio_enabled';
  static bool _isAudioEnabled = true;
  static bool _initialized = false;

  static bool get isAudioEnabled => _isAudioEnabled;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAudioEnabled = prefs.getBool(_prefKey) ?? true;
      _initialized = true;
    } catch (_) {
      _isAudioEnabled = true;
    }
  }

  static Future<void> toggleAudio() async {
    _isAudioEnabled = !_isAudioEnabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, _isAudioEnabled);
    } catch (_) {}
  }

  static Future<void> playCorrectSound() async {
    if (!_isAudioEnabled) return;
    if (kIsWeb) {
      _playWebSynthNotes([
        _SynthNote(freq: 523.25, duration: 0.12, startDelay: 0.0), // C5
        _SynthNote(freq: 659.25, duration: 0.12, startDelay: 0.08), // E5
        _SynthNote(freq: 783.99, duration: 0.22, startDelay: 0.16), // G5
      ]);
    }
  }

  static Future<void> playIncorrectSound() async {
    if (!_isAudioEnabled) return;
    if (kIsWeb) {
      _playWebSynthNotes([
        _SynthNote(freq: 311.13, duration: 0.15, startDelay: 0.0, waveType: 'sine'), // Eb4
        _SynthNote(freq: 261.63, duration: 0.25, startDelay: 0.12, waveType: 'sine'), // C4
      ]);
    }
  }

  static Future<void> playStreakSound(int streak) async {
    if (!_isAudioEnabled) return;
    if (kIsWeb) {
      if (streak >= 10) {
        _playWebSynthNotes([
          _SynthNote(freq: 523.25, duration: 0.10, startDelay: 0.0),
          _SynthNote(freq: 659.25, duration: 0.10, startDelay: 0.08),
          _SynthNote(freq: 783.99, duration: 0.10, startDelay: 0.16),
          _SynthNote(freq: 1046.50, duration: 0.35, startDelay: 0.24),
        ]);
      } else if (streak >= 5) {
        _playWebSynthNotes([
          _SynthNote(freq: 587.33, duration: 0.10, startDelay: 0.0),
          _SynthNote(freq: 739.99, duration: 0.10, startDelay: 0.08),
          _SynthNote(freq: 880.00, duration: 0.25, startDelay: 0.16),
        ]);
      } else {
        playCorrectSound();
      }
    }
  }

  static void _playWebSynthNotes(List<_SynthNote> notes) {
    try {
      final audioContextClass = _window.getProperty('AudioContext'.toJS) ?? _window.getProperty('webkitAudioContext'.toJS);
      if (audioContextClass != null) {
        final ctx = (audioContextClass as JSFunction).callAsConstructor<JSObject>();
        final currentTime = ((ctx.getProperty('currentTime'.toJS) as JSNumber).toDartDouble);

        for (final note in notes) {
          final osc = (ctx.callMethod('createOscillator'.toJS) as JSObject);
          final gain = (ctx.callMethod('createGain'.toJS) as JSObject);

          osc.callMethod('connect'.toJS, gain);
          gain.callMethod('connect'.toJS, ctx.getProperty('destination'.toJS));
          osc.setProperty('type'.toJS, note.waveType.toJS);

          final startTime = currentTime + note.startDelay;
          final freqParam = (osc.getProperty('frequency'.toJS) as JSObject);
          freqParam.callMethod('setValueAtTime'.toJS, note.freq.toJS, startTime.toJS);

          final gainParam = (gain.getProperty('gain'.toJS) as JSObject);
          gainParam.callMethod('setValueAtTime'.toJS, 0.12.toJS, startTime.toJS);
          gainParam.callMethod('exponentialRampToValueAtTime'.toJS, 0.001.toJS, (startTime + note.duration).toJS);

          osc.callMethod('start'.toJS, startTime.toJS);
          osc.callMethod('stop'.toJS, (startTime + note.duration).toJS);
        }
      }
    } catch (_) {}
  }
}

class _SynthNote {
  final double freq;
  final double duration;
  final double startDelay;
  final String waveType;

  _SynthNote({
    required this.freq,
    required this.duration,
    required this.startDelay,
    this.waveType = 'sine',
  });
}
