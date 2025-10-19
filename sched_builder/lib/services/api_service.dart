import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/event.dart';
import '../models/briefing.dart';

class ApiService {
  static const String baseUrl = 'http://your-backend-api.com';

  // Fetch events for a specific date
  Future<List<Event>> fetchEvents(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$baseUrl/events?date=$dateStr'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Event.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      throw Exception('Error fetching events: $e');
    }
  }

  // Upload audio for transcription and event creation
  Future<Event> uploadAudio(String audioFilePath, String description) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/events/create-from-audio'),
      );

      request.files.add(await http.MultipartFile.fromPath('audio', audioFilePath));
      request.fields['description'] = description;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final json = jsonDecode(responseBody);
        return Event.fromJson(json as Map<String, dynamic>);
      } else {
        throw Exception('Failed to create event from audio');
      }
    } catch (e) {
      throw Exception('Error uploading audio: $e');
    }
  }

  // Fetch audio briefing for the day
  Future<AudioBriefing> getAudioBriefing(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$baseUrl/briefing?date=$dateStr'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return AudioBriefing.fromJson(json as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load briefing');
      }
    } catch (e) {
      throw Exception('Error fetching briefing: $e');
    }
  }
}
