import 'package:flutter/material.dart';

enum EventType { symptom, medication }

class HistoryEvent {
  final String id;
  final String title;
  final DateTime date;
  final Color color;
  final EventType type;

  // Who this event belongs to. Kept on the event so the history view can group
  // a day's entries per person without re-joining against the family list.
  final String familyMemberId;
  final String memberName;

  // How many times this event happened on its day for this family member.
  // Repeats of the same medication/symptom collapse into a single event, and
  // this records the tally (e.g. taken 2× that day). Always >= 1.
  final int count;

  HistoryEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.color,
    required this.type,
    this.familyMemberId = '',
    this.memberName = '',
    this.count = 1,
  });
}
