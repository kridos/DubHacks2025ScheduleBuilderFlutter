class AudioBriefing {
  final String audioUrl;
  final String transcription;

  AudioBriefing({
    required this.audioUrl,
    required this.transcription,
  });

  factory AudioBriefing.fromJson(Map<String, dynamic> json) {
    return AudioBriefing(
      audioUrl: json['audioUrl'] as String,
      transcription: json['transcription'] as String,
    );
  }
}