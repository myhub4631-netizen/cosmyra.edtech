import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_feedback_stub.dart'
    if (dart.library.js_interop) 'audio_feedback_web.dart' as web_audio;

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
      web_audio.playWebSynthNotes([
        web_audio.SynthNoteItem(freq: 523.25, duration: 0.12, startDelay: 0.0),
        web_audio.SynthNoteItem(freq: 659.25, duration: 0.12, startDelay: 0.08),
        web_audio.SynthNoteItem(freq: 783.99, duration: 0.22, startDelay: 0.16),
      ]);
    }
  }

  static Future<void> playIncorrectSound() async {
    if (!_isAudioEnabled) return;
    if (kIsWeb) {
      web_audio.playWebSynthNotes([
        web_audio.SynthNoteItem(freq: 311.13, duration: 0.15, startDelay: 0.0, waveType: 'sine'),
        web_audio.SynthNoteItem(freq: 261.63, duration: 0.25, startDelay: 0.12, waveType: 'sine'),
      ]);
    }
  }

  static Future<void> playStreakSound(int streak) async {
    if (!_isAudioEnabled) return;
    if (kIsWeb) {
      if (streak >= 10) {
        web_audio.playWebSynthNotes([
          web_audio.SynthNoteItem(freq: 523.25, duration: 0.10, startDelay: 0.0),
          web_audio.SynthNoteItem(freq: 659.25, duration: 0.10, startDelay: 0.08),
          web_audio.SynthNoteItem(freq: 783.99, duration: 0.10, startDelay: 0.16),
          web_audio.SynthNoteItem(freq: 1046.50, duration: 0.35, startDelay: 0.24),
        ]);
      } else if (streak >= 5) {
        web_audio.playWebSynthNotes([
          web_audio.SynthNoteItem(freq: 587.33, duration: 0.10, startDelay: 0.0),
          web_audio.SynthNoteItem(freq: 739.99, duration: 0.10, startDelay: 0.08),
          web_audio.SynthNoteItem(freq: 880.00, duration: 0.25, startDelay: 0.16),
        ]);
      } else {
        playCorrectSound();
      }
    }
  }
}
