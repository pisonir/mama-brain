import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mama_brain/src/features/symptoms/ui/add_symptom_sheet.dart';

import '../../medications/ui/date_strip.dart';
import '../logic/symptom_provider.dart';
import '../../../core/models/symptom.dart';
import '../../family/logic/family_provider.dart';

class SymptomsPage extends ConsumerWidget {
  const SymptomsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptoms = ref.watch(dailySymptomProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptoms Log'),
        centerTitle: true,
        backgroundColor: Colors.pink.shade50,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const DateStrip(),
          const SizedBox(height: 10),

          Expanded(
            child: symptoms.isEmpty
                ? const Center(child: Text('No symptoms recorded.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: symptoms.length,
                    itemBuilder: (context, index) {
                      return _TimelineItem(symptom: symptoms[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink.shade100,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const AddSymptomSheet(),
          );
        },
        child: const Icon(Icons.add_reaction),
      ),
    );
  }
}

class _TimelineItem extends ConsumerWidget {
  final Symptom symptom;
  const _TimelineItem({required this.symptom});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyList = ref.watch(familyProvider);
    final member = familyList.firstWhere(
      (m) => m.id == symptom.familyMemberId,
      orElse: () => familyList.first,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TIME COLUMN
          SizedBox(
            width: 50,
            child: Text(
              DateFormat('HH:mm').format(symptom.timestamp),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          // THE LINE & DOT
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(member.colorValue),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(child: Container(width: 2, color: Colors.grey.shade200)),
            ],
          ),

          const SizedBox(width: 16),

          // THE CONTENT CARD
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.name,
                          style: TextStyle(
                            color: Color(member.colorValue),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(icon: const Icon(Icons.more_horiz, size: 16, color: Colors.grey),
                          onSelected: (value) {
                            if (value == 'delete') {
                              ref.read(symptomProvider.notifier).deleteSymptom(symptom.id);
                            } else if (value == 'edit') {
                              showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => AddSymptomSheet(symptomToEdit: symptom));
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blueGrey, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSymptomTitle(symptom),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (symptom.note != null && symptom.note!.isNotEmpty)
                      Text(
                        symptom.note!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSymptomTitle(Symptom s) {
    switch (s.type) {
      case SymptomType.fever:
        return "Fever ${s.data['temp']} °C";
      case SymptomType.cough:
        return '${s.data['style']} Cough';
      case SymptomType.vomit:
        return 'Vomiting';
      default:
        return s.type.name.toUpperCase();
    }
  }
}
