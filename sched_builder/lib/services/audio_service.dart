import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioRecorder _record = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  String? _recordingPath;

  Future<bool> startRecording() async {
  try {
    final hasPermission = await _record.hasPermission();
    if (!hasPermission) return false;
    

    final dir = '/data/user/0/com.example.schedule_app/cache';
    _recordingPath =
        '$dir/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _record.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _recordingPath!,
    );

    return true;
  } catch (e) {
    throw Exception('Error starting recording: $e');
  }
}

  Future<String?> stopRecording() async {
    try {
      await _record.stop();
      return _recordingPath;
    } catch (e) {
      throw Exception('Error stopping recording: $e');
    }
  }

  Future<void> playAudio(String url) async {
    try {
      await _player.play(UrlSource(url));
    } catch (e) {
      throw Exception('Error playing audio: $e');
    }
  }

  Future<void> pauseAudio() async {
    await _player.pause();
  }

  Future<void> stopAudio() async {
    await _player.stop();
  }

  void dispose() {
    _record.dispose();
    _player.dispose();
  }
}