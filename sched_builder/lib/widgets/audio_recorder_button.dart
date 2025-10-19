import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';

class AudioRecorderButton extends StatefulWidget {
  const AudioRecorderButton({Key? key}) : super(key: key);

  @override
  State<AudioRecorderButton> createState() => _AudioRecorderButtonState();
}

class _AudioRecorderButtonState extends State<AudioRecorderButton> {
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<EventProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: provider.isRecording
                  ? () => _showStopDialog(context, provider)
                  : () => _startRecording(context, provider),
              icon: Icon(provider.isRecording ? Icons.stop : Icons.mic),
              label: Text(provider.isRecording ? 'Stop Recording' : 'Record Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: provider.isRecording ? Colors.red : Colors.blue,
              ),
            ),
          ],
        );
      },
    );
  }

  void _startRecording(BuildContext context, EventProvider provider) {
    provider.startRecording();
  }

  void _showStopDialog(BuildContext context, EventProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Event Description'),
          content: TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(hintText: 'Describe the event'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                provider.stopRecordingAndUpload(_descriptionController.text);
                _descriptionController.clear();
                Navigator.pop(context);
              },
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}