import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';

class AudioRecorderButton extends StatefulWidget {
  const AudioRecorderButton({Key? key}) : super(key: key);

  @override
  State<AudioRecorderButton> createState() => _AudioRecorderButtonState();
}

class _AudioRecorderButtonState extends State<AudioRecorderButton> {
  static const Color kGradientStart = Color(0xFF7250E8);
  static const Color kGradientEnd = Color(0xFFE1306C);
  static const Color kRedGradientEnd = Color(0xFFB71C1C);

  @override
  Widget build(BuildContext context) {
    return Consumer<EventProvider>(
      builder: (context, provider, _) {
        final bool isRecording = provider.isRecording;
        final Gradient gradient = isRecording
            ? LinearGradient(
                colors: [kGradientEnd, kRedGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [kGradientStart, kGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );
        return Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: isRecording
                  ? () => _stopRecording(context, provider)
                  : () => _startRecording(context, provider),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isRecording ? Icons.stop : Icons.mic, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      isRecording ? 'Stop Recording' : 'Record Event',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startRecording(BuildContext context, EventProvider provider) {
    provider.startRecording();
  }

  void _stopRecording(BuildContext context, EventProvider provider) async {
    // Automatically stop and upload
    await provider.stopRecordingAndUpload('');
    // You could show a snackbar if you want feedback
    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.error}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording uploaded successfully')),
      );
    }
  }
}
