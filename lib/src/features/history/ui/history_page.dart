import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/models/family_member.dart';
import '../../family/logic/family_provider.dart';
import '../logic/history_event.dart';
import '../logic/history_grouping.dart';
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

  // Height of one week row. Tall enough for the day number plus three compact
  // event lines underneath it.
  static const double _rowHeight = 78;

  // Most lines shown under a day number. When a day has more events than this,
  // the last line becomes a "+N" tally so the cell never grows past three.
  static const int _maxCellLines = 3;

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(historyEventsProvider);
    final familyMembers = ref.watch(familyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family History'),
        centerTitle: true,
      ),
      // The whole page scrolls. With taller calendar rows a six-week month is
      // too tall for a fixed column on smaller phones, which would clip the
      // day list underneath it.
      body: ListView(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2026, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            rowHeight: _rowHeight,
            // Only horizontal swipes change the month, so vertical drags scroll
            // the page instead of fighting the calendar.
            availableGestures: AvailableGestures.horizontalSwipe,

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

            // Fully custom cells: day number on top, then compact event labels
            // (medications first, then symptoms) coloured per family member.
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) => _buildCell(day, events),
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
          if (_selectedDay == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Select a day to see details.')),
            )
          else
            _buildDayDetails(events),
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

  // A single calendar cell: the day number on top, then up to three compact
  // event lines (medications first, then symptoms) tinted with the family
  // member's colour.
  //
  // The column is top-aligned and fills the cell height, so the day number sits
  // at exactly the same height on every day — busy or empty (issue #3).
  Widget _buildCell(
    DateTime day,
    Map<DateTime, List<HistoryEvent>> allEvents, {
    bool isToday = false,
    bool isSelected = false,
    bool isOutside = false,
  }) {
    final normalized = DateTime(day.year, day.month, day.day);
    final dayEvents = allEvents[normalized] ?? [];

    // Keep the total number of lines under the day number at _maxCellLines: on
    // a busy day the last line is given over to the "+N" tally.
    final needsTally = dayEvents.length > _maxCellLines;
    final visible =
        dayEvents.take(needsTally ? _maxCellLines - 1 : _maxCellLines).toList();
    final overflow = dayEvents.length - visible.length;

    BoxDecoration? numberDecoration;
    Color numberColor;
    if (isSelected) {
      numberDecoration =
          const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle);
      numberColor = Colors.white;
    } else if (isToday) {
      numberDecoration =
          const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle);
      numberColor = Colors.white;
    } else {
      numberColor = isOutside ? Colors.grey.shade400 : Colors.black87;
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        // Fill the cell and pin content to the top so every day number lines up
        // on the same baseline, however many events a day has.
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
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
                style: const TextStyle(fontSize: 8, height: 1.2, color: Colors.grey),
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

  // The list below the calendar, grouped per person so you can read through one
  // person's day before moving to the next (issue #3). The medication/symptom
  // category is intentionally not shown — the entry name already says what it
  // is, and dropping it keeps the rows compact.
  Widget _buildDayDetails(Map<DateTime, List<HistoryEvent>> allEvents) {
    final normalized =
        DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final dayEvents = allEvents[normalized] ?? [];

    if (dayEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text('No events for this day.')),
      );
    }

    final family = ref.watch(familyProvider);
    final sections = groupEventsByPerson(dayEvents, family);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final section in sections) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: section.color,
                    child: Text(
                      section.memberName.isNotEmpty
                          ? section.memberName.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    section.memberName,
                    style: TextStyle(
                      color: section.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Divider(color: section.color.withValues(alpha: 0.3)),
                  ),
                ],
              ),
            ),
            for (final event in section.events)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      event.type == EventType.medication
                          ? Icons.medication_liquid
                          : Icons.thermostat,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.count > 1
                            ? '${event.title}  ×${event.count}'
                            : event.title,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
