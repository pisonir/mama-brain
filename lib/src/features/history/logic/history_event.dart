import 'package:flutter/material.dart';

enum EventType { symptom, medication }

class HistoryEvent {
  final String id;
  final String title;
  final DateTime date;
  final Color color;
  final EventType type;

  HistoryEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.color,
    required this.type,
  });
}