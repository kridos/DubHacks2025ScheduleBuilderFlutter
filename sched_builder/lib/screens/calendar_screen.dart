import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/event_provider.dart';
import '../widgets/audio_recorder_button.dart';
import '../widgets/event_list.dart';
import '../widgets/loading_indicator.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().fetchEventsForDate(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventProvider>(
      builder: (context, provider, _) {
        return LoadingIndicator(
          isLoading: provider.isLoading,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Schedule'),
              elevation: 0,
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Calendar Widget
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: TableCalendar(
                      firstDay: DateTime(2024),
                      lastDay: DateTime(2026),
                      focusedDay: provider.selectedDate,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, provider.selectedDate),
                      onDaySelected: (selectedDay, focusedDay) {
                        provider.fetchEventsForDate(selectedDay);
                      },
                    ),
                  ),

                  // Error message
                  if (provider.error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // Events list
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Events',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  EventList(events: provider.events),

                  // Audio recorder
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: AudioRecorderButton(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}