import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mama_brain/src/features/medications/logic/date_provider.dart';
import '../../../core/models/symptom.dart';
import '../../family/logic/family_provider.dart';
import '../logic/symptom_provider.dart';

class AddSymptomSheet extends ConsumerStatefulWidget {
  final Symptom? symptomToEdit;

  const AddSymptomSheet({super.key, this.symptomToEdit});

  @override
  ConsumerState<AddSymptomSheet> createState() => _AddSymptomSheetState();
}

class _AddSymptomSheetState extends ConsumerState<AddSymptomSheet> {
  // STATE VARIABLES
  String? _selectedMemberId;
  SymptomType _selectedType = SymptomType.fever; // Default

  double _tempValue = 38.5;
  String _coughType = 'Dry';
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.symptomToEdit != null) {
      final symptom = widget.symptomToEdit!;
      _selectedMemberId = symptom.familyMemberId;
      _selectedType = symptom.type;
      _noteController.text = symptom.note ?? '';

      if (symptom.type == SymptomType.fever &&
          symptom.data.containsKey('temp')) {
        _tempValue = (symptom.data['temp'] as num).toDouble();
      } else if (symptom.type == SymptomType.cough &&
          symptom.data.containsKey('style')) {
        _coughType = symptom.data['style'];
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final familyMembers = ref.read(familyProvider);
        if (familyMembers.isNotEmpty && _selectedMemberId == null) {
          setState(() {
            _selectedMemberId = familyMembers.first.id;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyMembers = ref.watch(familyProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Add Symptom",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // WHO?
          if (familyMembers.isEmpty)
            const Text(
              "Please add a family member first in the Medications tab.",
              style: TextStyle(color: Colors.red),
            )
          else
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: familyMembers.length,
                itemBuilder: (context, index) {
                  final member = familyMembers[index];
                  final isSelected = member.id == _selectedMemberId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(member.name),
                      selected: isSelected,
                      avatar: isSelected
                          ? null
                          : CircleAvatar(
                              backgroundColor: Color(member.colorValue),
                              child: Text(
                                member.name[0],
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                      onSelected: (selected) {
                        setState(() => _selectedMemberId = member.id);
                      },
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),

          // The Chips Grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: SymptomType.values.map((type) {
              final isSelected = _selectedType == type;
              return FilterChip(
                label: Text(type.name.toUpperCase()),
                selected: isSelected,
                showCheckmark: false,
                color: WidgetStatePropertyAll(
                  isSelected ? Colors.pink.shade100 : null,
                ),
                onSelected: (selected) {
                  setState(() => _selectedType = type);
                },
                avatar: Icon(_getIconForType(type), size: 18),
              );
            }).toList(),
          ),

          const Divider(height: 30),

          // DETAILS
          _buildDynamicDetails(),

          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: "Note (Optional)",
              hintText: "e.g. Gave water, sleeping now",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          // SAVE BUTTON
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveSymptom,
              child: const Text("Save Entry"),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  IconData _getIconForType(SymptomType type) {
    switch (type) {
      case SymptomType.fever:
        return Icons.thermostat;
      case SymptomType.cough:
        return Icons.masks;
      case SymptomType.vomit:
        return Icons.sick;
      case SymptomType.pain:
        return Icons.healing;
      case SymptomType.rash:
        return Icons.grid_on;
      case SymptomType.other:
        return Icons.help_outline;
    }
  }

  void _saveSymptom() {
    if (_selectedMemberId == null) return;

    Map<String, dynamic> data = {};
    if (_selectedType == SymptomType.fever) {
      data['temp'] = double.parse(_tempValue.toStringAsFixed(1));
    } else if (_selectedType == SymptomType.cough) {
      data['style'] = _coughType;
    }

    // Edit mode
    if (widget.symptomToEdit != null) {
      ref
          .read(symptomProvider.notifier)
          .editSymptom(
            id: widget.symptomToEdit!.id,
            familyMemberId: _selectedMemberId!,
            type: _selectedType,
            timestamp: widget.symptomToEdit!.timestamp,
            data: data,
            note: _noteController.text.isEmpty ? null : _noteController.text,
          );
    }
    // Add mode
    else {
      final selectedDate = ref.read(selectedDateProvider);
      final now = DateTime.now();
      final timestamp = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        now.hour,
        now.minute,
      );
      ref
          .read(symptomProvider.notifier)
          .addSymptom(
            familyMemberId: _selectedMemberId!,
            type: _selectedType,
            timestamp: timestamp,
            data: data,
            note: _noteController.text.isEmpty ? null : _noteController.text,
          );
    }

    Navigator.pop(context);
  }

  Widget _buildDynamicDetails() {
    // TODO: Return different widgets based on _selectedType
    // If fever -> return a  Slider
    // If cough -> return a SegmentedButton or ChoiceChips
    // Else -> Return empty SizedBox()
    switch (_selectedType) {
      case SymptomType.fever:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Temperature (°C)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _tempValue,
              min: 35.0,
              max: 42.0,
              divisions: 70,
              label: _tempValue.toStringAsFixed(1),
              onChanged: (value) {
                setState(() => _tempValue = value);
              },
            ),
          ],
        );
      case SymptomType.cough:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cough Type",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 10,
              children: ['Dry', 'Wet', 'Whooping'].map((type) {
                final isSelected = _coughType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _coughType = type);
                  },
                );
              }).toList(),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
