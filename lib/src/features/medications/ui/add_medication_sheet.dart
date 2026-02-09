import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/medication.dart';
import '../../family/logic/family_provider.dart';
import '../logic/medication_provider.dart';

class AddMedicationSheet extends ConsumerStatefulWidget {
  final Medication? medicationToEdit; 

  const AddMedicationSheet({super.key, this.medicationToEdit});

  @override
  ConsumerState<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends ConsumerState<AddMedicationSheet> {
  late final TextEditingController _nameController;

  // We default to "One Off" as it's the most common
  MedicationType _selectedType = MedicationType.oneOff;

  // default duration for temporary meds is 5 days
  double _durationDays = 5;

  // We make it nullable (?) because initially, no one might be selected
  String? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    if (widget.medicationToEdit != null) {
      final med = widget.medicationToEdit!;
      _nameController.text = med.name;
      _selectedType = med.type;
      _selectedMemberId = med.familyMemberId;
      if (med.durationInDays != null) {
        _durationDays = med.durationInDays!.toDouble();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Helper to update name from quick chips
  void _fillName(String name) {
    _nameController.text = name;
    // Move cursor to end
    _nameController.selection = TextSelection.fromPosition(
      TextPosition(offset: name.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the family list so we can show avatars
    final familyMembers = ref.watch(familyProvider);

    // Select the first one by default if none selected
    if (_selectedMemberId == null && familyMembers.isNotEmpty) {
      _selectedMemberId = familyMembers.first.id;
    }

    return Padding(
      // This padding makes the sheet avoid the keyboard when it opens
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
          const Text("New Medication", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Family Member Selection, horizontal scroll
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: familyMembers.length,
              itemBuilder:(context, index) {
                final member = familyMembers[index];
                final isSelected = member.id == _selectedMemberId;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(member.name),
                    selected: isSelected,
                    // Show a checkmark if selected
                    avatar: isSelected ? null : CircleAvatar(
                    backgroundColor: Color(member.colorValue),
                    child: Text(member.name[0], style: const TextStyle(fontSize: 10)),
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedMemberId = member.id;
                    });
                  },
                ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Medication Name Input
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "Medication Name",
              hintText: "e.g., Ibuprofen",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          // Quick Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                "Ibuprofen",
                "Paracetamol",
                "Antibiotic",
                "Vitamin D",
                "Iron"
              ].map((name) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(name),
                  onPressed: () => _fillName(name),
                ),
              )).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Type Selection
          SegmentedButton<MedicationType>(
            segments: const [
              ButtonSegment<MedicationType>(
                value: MedicationType.oneOff,
                label: Text("One Off"),
              ),
              ButtonSegment<MedicationType>(
                value: MedicationType.temporary,
                label: Text("Temporary"),
              ),
              ButtonSegment<MedicationType>(
                value: MedicationType.permanent,
                label: Text("Permanent"),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (Set<MedicationType> newSelection) {
              setState(() {
                _selectedType = newSelection.first;
              });
            },
          ),

          // Duration Slider for Temporary type
          if (_selectedType == MedicationType.temporary) ...[
            const SizedBox(height: 16),
            Text("Duration: ${_durationDays.toInt()} days"),
            Slider(
              value: _durationDays,
              min: 1,
              max: 14,
              divisions: 13,
              label: _durationDays.toInt().toString(),
              onChanged: (double value) {
                setState(() {
                  _durationDays = value;
                });
              },
            ),
          ],

          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty && _selectedMemberId != null) {
                // EDIT MODE
                if (widget.medicationToEdit != null) {
                  ref.read(medicationProvider.notifier).editMedication(
                    id: widget.medicationToEdit!.id,
                    name: _nameController.text,
                    familyMemberId: _selectedMemberId!,
                    type: _selectedType,
                    durationInDays: _selectedType == MedicationType.temporary ? _durationDays.toInt() : null,
                    originalStartDate: widget.medicationToEdit!.startDate,
                  );
                } 
                // ADD MODE
                else {
                  ref.read(medicationProvider.notifier).addMedication(
                    name: _nameController.text.trim(),
                    familyMemberId: _selectedMemberId!,
                    type: _selectedType,
                    startDate: DateTime.now(),
                    durationInDays: _selectedType == MedicationType.temporary ? _durationDays.toInt() : null,
                  );
                }

                Navigator.pop(context);
                }
              },
              child: Text(widget.medicationToEdit != null ? "Update Medication" : "Save Medication"),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

