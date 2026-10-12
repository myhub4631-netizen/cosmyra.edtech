class SynthNoteItem {
  final double freq;
  final double duration;
  final double startDelay;
  final String waveType;

  SynthNoteItem({
    required this.freq,
    required this.duration,
    required this.startDelay,
    this.waveType = 'sine',
  });
}

void playWebSynthNotes(List<SynthNoteItem> notes) {
  // No-op on native Android/iOS
}
