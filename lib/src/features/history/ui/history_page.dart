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
              // Show a small dot per family member with an event that day,
              // anchored to the bottom of the cell so the day number
              // (centered by default) always stays readable — even on busy
              // days. Full event details are listed below once a day is
              // selected, so no information is lost by keeping this compact.
              markerBuilder: (context, date, dayEvents) {
                if (dayEvents.isEmpty) return const SizedBox();
                return _buildDayMarkers(dayEvents.cast<HistoryEvent>());
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

  // Compact dot indicators for a calendar cell: one dot per family member
  // with an event that day (deduped by their color), capped so the row
  // never grows tall enough to overlap the day number above it.
  Widget _buildDayMarkers(List<HistoryEvent> dayEvents) {
    const maxDots = 4;

    final memberColors = <Color>[];
    for (final event in dayEvents) {
      if (!memberColors.contains(event.color)) memberColors.add(event.color);
    }

    final visibleColors = memberColors.take(maxDots).toList();
    final overflow = memberColors.length - visibleColors.length;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final color in visibleColors)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            if (overflow > 0)
              Padding(
                padding: const EdgeInsets.only(left: 1),
                child: Text(
                  '+$overflow',
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
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