import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _selectedTimeZone = 'UTC';

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
  String get selectedTimeZone => _selectedTimeZone;

  // Constructor that loads saved timezone
  EventProvider() {
    _loadTimeZone();
  }

  // --- Load time zone from local storage ---
  Future<void> _loadTimeZone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedTimeZone = prefs.getString('selectedTimeZone') ?? 'UTC';
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading timezone: $e");
      _selectedTimeZone = 'UTC';
    }
  }

  // --- Google Calendar OAuth Setup ---
  void setAccessToken(String token) {
    _accessToken = token;
    _googleConnected = true;
    notifyListeners();
  }

  // --- Set and save time zone ---
  Future<void> setTimeZone(String timeZone) async {
    _selectedTimeZone = timeZone;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedTimeZone', timeZone);
    } catch (e) {
      debugPrint("Error saving timezone: $e");
    }
    notifyListeners();
  }

  // --- Fetch events (from API and optionally Google Calendar) ---
  Future<void> fetchEventsForDate(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Fetch your app's backend events
      //final localEvents = await _apiService.fetchEvents(date);
      // Step 2: Fetch Google Calendar events (if connected)
      List<Event> googleEvents = [];
      if (_accessToken != null) {
        googleEvents = await _fetchGoogleCalendarEvents(date);
      }

      

      // Combine or prioritize
      _events = [...googleEvents];
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
      
      debugPrint("Access Token: $_accessToken");
      final credentials = AccessCredentials(
        AccessToken(
          'Bearer', 
          _accessToken!, 
          DateTime.now().toUtc().add(const Duration(hours: 1))
        ),
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

  // --- Audio Recording Logic ---
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




      final newEvent = await _apiService.uploadAudio(
        audioPath,
        _accessToken ?? '',
        _selectedTimeZone,
      );
      _events = await _fetchGoogleCalendarEvents(DateTime.now());
      _stats = ScheduleStats.calculate(_events, _selectedDate);
    }
  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  // --- Add Event by Text ---
  Future<void> addEventByText(String eventText) async {
    if (eventText.trim().isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.addEventByText(eventText, _accessToken ?? '', _selectedTimeZone);
      _events = await _fetchGoogleCalendarEvents(DateTime.now());
      _stats = ScheduleStats.calculate(_events, _selectedDate);
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
      String _briefing = await _apiService.getAudioBriefing(date,  _accessToken ?? '', _selectedTimeZone);
      debugPrint("Briefing fetched: ${_briefing}");

      if (_briefing != null && _briefing!.isNotEmpty) {
      try {
        await _audioService.playAudio(_briefing);
      } catch (e) {
        _error = e.toString();
        notifyListeners();
      }
  }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> uploadEventImage(String imagePath) async {
  try {
    _isLoading = true;
    notifyListeners();

    final newEvent = await _apiService.uploadImage(
      imagePath,
      _accessToken ?? '',
      _selectedTimeZone,
    );
    _events = await _fetchGoogleCalendarEvents(DateTime.now());
    _stats = ScheduleStats.calculate(_events, _selectedDate);
  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}


  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}