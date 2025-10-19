import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart';
import '../models/event.dart';
import '../models/stats.dart';
import '../models/briefing.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import 'package:http/http.dart' as http;


class EventProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AudioService _audioService = AudioService();

  List<Event> _events = [];
  ScheduleStats? _stats;
  AudioBriefing? _briefing;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isRecording = false;
  String? _error;

  // Google Calendar fields
  String? _accessToken;
  bool _googleConnected = false;

  // Getters
  List<Event> get events => _events;
  ScheduleStats? get stats => _stats;
  AudioBriefing? get briefing => _briefing;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  bool get isRecording => _isRecording;
  String? get error => _error;
  bool get googleConnected => _googleConnected;

  // --- Google Calendar OAuth Setup ---
  void setAccessToken(String token) {
    _accessToken = token;
    _googleConnected = true;
    notifyListeners();
  }

  // --- Fetch events (from API and optionally Google Calendar) ---
  Future<void> fetchEventsForDate(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Fetch your app’s backend events
      final localEvents = await _apiService.fetchEvents(date);

      // Step 2: Fetch Google Calendar events (if connected)
      List<Event> googleEvents = [];
      if (_accessToken != null) {
        googleEvents = await _fetchGoogleCalendarEvents(date);
      }

      // Combine or prioritize
      _events = [...localEvents, ...googleEvents];
      _stats = ScheduleStats.calculate(_events, date);
      _selectedDate = date;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Fetch Google Calendar events ---
  Future<List<Event>> _fetchGoogleCalendarEvents(DateTime date) async {
  try {
    final credentials = AccessCredentials(
      AccessToken('Bearer', _accessToken!, DateTime.now().add(const Duration(hours: 1))),
      null,
      [calendar.CalendarApi.calendarScope],
    );

    // Create a base HTTP client
    final baseClient = http.Client();
    // Wrap it with authentication
    final client = authenticatedClient(baseClient, credentials);

    final calendarApi = calendar.CalendarApi(client);

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final eventsList = await calendarApi.events.list(
      "primary",
      timeMin: start.toUtc(),
      timeMax: end.toUtc(),
      singleEvents: true,
      orderBy: "startTime",
    );

    client.close();

    return (eventsList.items ?? [])
        .map((e) => Event(
              id: e.id ?? '',
              title: e.summary ?? '(No title)',
              description: e.description ?? '',
              startTime: e.start?.dateTime?.toLocal() ?? start,
              endTime: e.end?.dateTime?.toLocal() ?? end,
            ))
        .toList();
  } catch (e) {
    debugPrint("Google Calendar fetch failed: $e");
    return [];
  }
}

  // --- Audio Recording Logic (unchanged) ---
  Future<void> startRecording() async {
    try {
      final success = await _audioService.startRecording();
      if (success) {
        _isRecording = true;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> stopRecordingAndUpload(String description) async {
    try {
      final audioPath = await _audioService.stopRecording();
      _isRecording = false;

      if (audioPath != null) {
        _isLoading = true;
        notifyListeners();

        final newEvent = await _apiService.uploadAudio(audioPath, description);
        _events.add(newEvent);
        _stats = ScheduleStats.calculate(_events, _selectedDate);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBriefing(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _briefing = await _apiService.getAudioBriefing(date);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> playBriefing() async {
    if (_briefing != null) {
      await _audioService.playAudio(_briefing!.audioUrl);
    }
  }

  Future<void> pauseBriefing() async {
    await _audioService.pauseAudio();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
