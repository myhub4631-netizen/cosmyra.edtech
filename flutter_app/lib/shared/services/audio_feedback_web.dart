import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'audio_feedback_stub.dart';

@JS('window')
external JSObject get _window;

void playWebSynthNotes(List<SynthNoteItem> notes) {
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
