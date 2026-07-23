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
            // Taller rows leave room for the day number plus a couple of
            // event labels underneath it without crowding.
            rowHeight: 70,

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

            // Fully custom cells: day number on top, then up to two compact
            // event labels (medication/symptom names) coloured per family
            // member. The number always stays visible above the labels.
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) =>
                  _buildCell(day, events),
              outsideBuilder: (context, day, _) =>
                  _buildCell(day, events, isOutside: true),
              todayBuilder: (context, day, _) =>
                  _buildCell(day, events, isToday: true),
              selectedBuilder: (context, day, _) =>
                  _buildCell(day, events, isSelected: true),
            ),

            calendarStyle: const CalendarStyle(
              cellMargin: EdgeInsets.all(2),
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

  // A single calendar cell: the day number on top, then up to two compact
  // event labels (medication/symptom names) tinted with the family member's
  // colour. Any further events collapse into a "+N" line. The number always
  // stays above the labels, so it's never covered.
  Widget _buildCell(
    DateTime day,
    Map<DateTime, List<HistoryEvent>> allEvents, {
    bool isToday = false,
    bool isSelected = false,
    bool isOutside = false,
  }) {
    final normalized = DateTime(day.year, day.month, day.day);
    final dayEvents = allEvents[normalized] ?? [];

    const maxLabels = 2;
    final visible = dayEvents.take(maxLabels).toList();
    final overflow = dayEvents.length - visible.length;

    BoxDecoration? numberDecoration;
    Color numberColor;
    if (isSelected) {
      numberDecoration = const BoxDecoration(
          color: Colors.blueAccent, shape: BoxShape.circle);
      numberColor = Colors.white;
    } else if (isToday) {
      numberDecoration = const BoxDecoration(
          color: Colors.orangeAccent, shape: BoxShape.circle);
      numberColor = Colors.white;
    } else {
      numberColor = isOutside ? Colors.grey.shade400 : Colors.black87;
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: numberDecoration,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                color: numberColor,
                fontWeight:
                    (isToday || isSelected) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          for (final event in visible)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 1),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  height: 1.2,
                  color: _contrastColor(event.color),
                ),
              ),
            ),
          if (overflow > 0)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                '+$overflow',
                style: const TextStyle(fontSize: 8, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  // Pick black or white text depending on how light the background colour is,
  // so labels stay readable on both pastel and dark family colours.
  Color _contrastColor(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
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
          title: Text(
            event.count > 1 ? '${event.title}  ×${event.count}' : event.title,
          ),
          subtitle: Text(event.type.name.toUpperCase()),
        );
      },
    );
  }
}