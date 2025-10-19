class Event {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;
  

  Event({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'description': description,
    };
  }

  Duration get duration => endTime.difference(startTime);
}