import 'package:mama_brain/src/features/medications/logic/date_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mama_brain/src/features/medications/logic/medication_provider.dart';

import '../../../core/models/medication.dart';

bool _shouldShowMedication(Medication med, DateTime selectedDate) {
  final date = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
  );
  final start = DateTime(
    med.startDate.year,
    med.startDate.month,
    med.startDate.day,
  );

  switch (med.type) {
    case MedicationType.oneOff:
      return date.isAtSameMomentAs(start);
    case MedicationType.permanent:
      return !start.isAfter(date); // start <= date
    case MedicationType.temporary:
      if (start.isAfter(date)) return false;

      final end = start.add(Duration(days: med.durationInDays ?? 0));
      return date.isBefore(end);
  }
}

final dailyMedicationsProvider = Provider<List<Medication>> ((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final allMeds = ref.watch(medicationProvider);

  return allMeds.where((med) => _shouldShowMedication(med, selectedDate)).toList();

});