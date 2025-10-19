import 'event.dart';

class ScheduleStats {
  final int totalEvents;
  final int busyHours;
  final int freeHours;
  final List<Event> events;

  ScheduleStats({
    required this.totalEvents,
    required this.busyHours,
    required this.freeHours,
    required this.events,
  });

  factory ScheduleStats.calculate(List<Event> events, DateTime date) {
    int busyMinutes = 0;
    for (var event in events) {
      if (event.startTime.year == date.year &&
          event.startTime.month == date.month &&
          event.startTime.day == date.day) {
        busyMinutes += event.duration.inMinutes;
      }
    }
    
    const dayMinutes = 24 * 60;
    final freeMinutes = dayMinutes - busyMinutes;
    
    return ScheduleStats(
      totalEvents: events.length,
      busyHours: busyMinutes ~/ 60,
      freeHours: freeMinutes ~/ 60,
      events: events,
    );
  }
}