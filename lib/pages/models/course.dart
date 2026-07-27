import 'package:flutter/material.dart';

class Course {
  String name;
  String room;
  String day;
  String time;
  int reminderMinutes;

  Course({
    required this.name,
    required this.room,
    required this.day,
    required this.time,
    this.reminderMinutes = 30,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'room': room,
    'day': day,
    'time': time,
    'reminderMinutes': reminderMinutes,
  };

  factory Course.fromMap(Map<String, dynamic> map) => Course(
      name: map['name'],
      room: map['room'],
      day: map['day'],
      time: map['time'],
      reminderMinutes: map['reminderMinutes'] ?? 30,
  );
}

// Global state
List<Course> userSchedule = [];
List<Reminder> userReminders = []; // Added for homework/quizzes
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(true);

class Reminder {
  String id;
  String type; // 'Homework' or 'Quiz'
  String course;
  String details;
  DateTime dueDate;
  int remindBeforeHours; // 6, 12, 24, 48, 72

  Reminder({
    required this.id,
    required this.type,
    required this.course,
    required this.details,
    required this.dueDate,
    required this.remindBeforeHours,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'course': course,
    'details': details,
    'dueDate': dueDate.toIso8601String(),
    'remindBeforeHours': remindBeforeHours,
  };

  factory Reminder.fromMap(Map<String, dynamic> map) => Reminder(
    id: map['id'],
    type: map['type'],
    course: map['course'],
    details: map['details'],
    dueDate: DateTime.parse(map['dueDate']),
    remindBeforeHours: map['remindBeforeHours'],
  );
}
