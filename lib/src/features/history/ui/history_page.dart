import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/models/family_member.dart';
import '../../family/logic/family_provider.dart';
import '../logic/history_event.dart';
import '../logic/history_provider.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(historyEventsProvider);
    final familyMembers = ref.watch(familyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family History'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2026, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,

            // Load events for a specific day
            eventLoader: (day) {
              final normalized = DateTime(day.year, day.month, day.day);
              return events[normalized] ?? [];
            },

            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay; // update focused day as well
              });
            },

            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },

            // Custom UI builders
            calendarBuilders: CalendarBuilders(
              // This controls how to 'markers' (dots/events) look
              markerBuilder: (context, date, dayEvents) {
                if (dayEvents.isEmpty) return const SizedBox();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Don't scroll inside the cell
                  itemCount: dayEvents.length,
                  itemBuilder: (context, index) {
                    final event = dayEvents[index] as HistoryEvent;
                    return _buildEventBar(event);
                  },
                );
              },
            ),

            // Styling
            calendarStyle: const CalendarStyle(
              cellMargin: EdgeInsets.all(2),
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Color legend for family members
          if (familyMembers.isNotEmpty) _buildFamilyLegend(familyMembers),

          // Legend / details for selected day
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Select a day to see details.'))
                : _buildDayDetails(events),
          ),
        ],
      ),
    );
  }

  // Horizontal legend showing each family member's color and name
  Widget _buildFamilyLegend(List<FamilyMember> members) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              'Members:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            ...members.map((member) => _buildLegendItem(member)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(FamilyMember member) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Color(member.colorValue),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            member.name,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // The tiny bar inside the calendar cell
  Widget _buildEventBar(HistoryEvent event) {
    final isSymptom = event.type == EventType.symptom;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0.5, horizontal:1),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      height: 14,
      decoration: BoxDecoration(
        color: isSymptom ? event.color : Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: isSymptom ? null : Border.all(color: event.color, width: 1),
      ),
      child: Text(
        event.title,
        style: TextStyle(
          color: isSymptom ? Colors.white : event.color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis, // Truncatte long text "Paracet..."
      ),
    );
  }

  // The list below the calendar
  Widget _buildDayDetails(Map<DateTime, List<HistoryEvent>> allEvents) {
    final normalized = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final dayEvents = allEvents[normalized] ?? [];

    if (dayEvents.isEmpty) {
      return const Center(child: Text('No events for this day.'));
    }

    return ListView.builder(
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        return ListTile(
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: event.color,
              shape: BoxShape.circle,
            ),
          ),
          title: Text(event.title),
          subtitle: Text(event.type.name.toUpperCase()),
        );
      },
    );
  }
}