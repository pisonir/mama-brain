import '../logic/date_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DateStrip extends ConsumerWidget {
  const DateStrip({super.key});

  // Helper to check if two dates are the same day (ignoring time)
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final centerDate = ref.watch(dateStripCenterProvider);
    final weekDates = getWeekDatesFrom(centerDate);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final currentDate = ref.read(dateStripCenterProvider);
              ref.read(dateStripCenterProvider.notifier).state =
                  currentDate.subtract(const Duration(days: 5));
            },
          ),

          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weekDates.map((date) {
                final isSelected = _isSameDay(date, selectedDate);
                final isToday = _isSameDay(date, DateTime.now());
                return GestureDetector(
                  onTap: () {
                    ref.read(selectedDateProvider.notifier).state = date;
                    // center the strip on the selected date
                    ref.read(dateStripCenterProvider.notifier).state = date;
                  },
                  child: _DateCard(
                    date: date,
                    isSelected: isSelected,
                    isToday: isToday,
                  ),
                );
              }).toList(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final currentDate = ref.read(dateStripCenterProvider);
              ref.read(dateStripCenterProvider.notifier).state =
                  currentDate.add(const Duration(days: 5));
            },
          ),
      ]),
    );
  }
}

class _DateCard extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;

  const _DateCard({required this.date, required this.isSelected, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: isSelected ? primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? null
            : isToday
                ? Border.all(color: primaryColor, width: 2)
                : Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isToday ? 'Today' : DateFormat('E').format(date),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Colors.white
                  : isToday
                      ? primaryColor
                      : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('d').format(date),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : isToday
                      ? primaryColor
                      : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}