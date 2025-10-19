import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/event.dart';
import '../models/briefing.dart';
import 'dart:io';

class ApiService {
  static const String baseUrl = 'http://your-backend-api.com';

  // Upload audio for transcription and event creation
  Future<void> uploadAudio(String audioPath, String accessToken, String timezone) async {
    try {
      final file = File(audioPath);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/addEventByAudio'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', audioPath),
      );

      request.fields['access_token'] = accessToken;
      request.fields['timezone'] = timezone;
      request.fields['curr_date'] = DateTime.now().toIso8601String();

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(responseBody);
      } else {
        throw Exception('Failed to create event from audio');
      }
    } catch (e) {
      throw Exception('Error uploading audio: $e');
    }
  }

  // Fetch audio briefing for the day
  Future<AudioBriefing> getAudioBriefing(
    DateTime date,
    String accessToken,
    String timezone,
  ) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/dailyBriefing'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': '',
          'access_token': accessToken,
          'timezone': timezone,
          'curr_date': dateStr,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return AudioBriefing.fromJson(json as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load briefing');
      }
    } catch (e) {
      throw Exception('Error fetching briefing: $e');
    }
  }


  // Add event by text input
  Future<void> addEventByText(String eventText, String accessToken, String timezone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/addEventByText'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': eventText,
          'access_token': accessToken,
          'timezone': timezone,
          'curr_date': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        //return Event.fromJson(json as Map<String, dynamic>);
      } else {
        throw Exception('Failed to create event from text');
      }
    } catch (e) {
      throw Exception('Error adding event by text: $e');
    }
  }

  Future<void> uploadImage(String imagePath, String accessToken, String timezone) async {
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/add-event-by-image'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('file', imagePath),
    );

    request.fields['access_token'] = accessToken;
    request.fields['timezone'] = timezone;

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonData = jsonDecode(responseData);
    } else {
      throw Exception('Failed to upload image: ${response.statusCode}');
    }
  } catch (e) {
    rethrow;
  }
}
}
