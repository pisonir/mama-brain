import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/medication.dart';
import '../../family/logic/family_provider.dart';
import '../logic/date_provider.dart';
import '../logic/medication_provider.dart';

class AddMedicationSheet extends ConsumerStatefulWidget {
  final Medication? medicationToEdit; 

  const AddMedicationSheet({super.key, this.medicationToEdit});

  @override
  ConsumerState<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends ConsumerState<AddMedicationSheet> {
  late final TextEditingController _nameController;

  // Tracks which quick-chip name is highlighted (null if user typed manually)
  String? _selectedQuickChipName;

  // We default to "One Off" as it's the most common
  MedicationType _selectedType = MedicationType.oneOff;

  // default duration for temporary meds is 5 days
  double _durationDays = 5;

  // We make it nullable (?) because initially, no one might be selected
  String? _selectedMemberId;

  // Date and time for when the medication was taken
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  static const _quickChipNames = [
    "Ibuprofen",
    "Paracetamol",
    "Antibiotic",
    "Navisin",
    "Antifungal Cream",
    "Vitamin D",
    "Iron",
  ];

  // Quick chips that should default to a specific type and duration
  static const _quickChipDefaults = <String, ({MedicationType type, int? days})>{
    "Navisin": (type: MedicationType.temporary, days: 7),
    "Antifungal Cream": (type: MedicationType.temporary, days: 7),
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    if (widget.medicationToEdit != null) {
      final med = widget.medicationToEdit!;
      _nameController.text = med.name;
      _selectedType = med.type;
      _selectedMemberId = med.familyMemberId;
      _selectedDate = med.startDate;
      _selectedTime = TimeOfDay.now();
      if (med.durationInDays != null) {
        _durationDays = med.durationInDays!.toDouble();
      }
      // Pre-highlight chip if editing a medication whose name matches one
      if (_quickChipNames.contains(med.name)) {
        _selectedQuickChipName = med.name;
      }
    } else {
      _selectedTime = TimeOfDay.now();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final selectedDate = ref.read(selectedDateProvider);
        if (mounted) {
          setState(() => _selectedDate = selectedDate);
        }
      });
      _selectedDate = DateTime.now();
    }
    // Clear chip highlight when user edits the text field manually
    _nameController.addListener(() {
      if (_selectedQuickChipName != null &&
          _nameController.text != _selectedQuickChipName) {
        setState(() => _selectedQuickChipName = null);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Helper to update name (and optionally type/duration) from quick chips
  void _fillName(String name) {
    final defaults = _quickChipDefaults[name];
    setState(() {
      _selectedQuickChipName = name;
      if (defaults != null) {
        _selectedType = defaults.type;
        if (defaults.days != null) {
          _durationDays = defaults.days!.toDouble();
        }
      }
    });
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
      // This padding makes the sheet avoid the keyboard when it opens,
      // and also accounts for the system navigation bar (Back/Home/Recents).
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
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
              children: _quickChipNames.map((name) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(name),
                  selected: name == _selectedQuickChipName,
                  onSelected: (_) => _fillName(name),
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

          const Divider(height: 30),

          // DATE PICKER ROW
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                DateFormat.yMMMd().format(_selectedDate),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => setState(() {
                  final now = DateTime.now();
                  _selectedDate = DateTime(now.year, now.month, now.day);
                }),
                child: const Text('Today'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Pick'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // TIME PICKER ROW
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                _selectedTime.format(context),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => setState(() => _selectedTime = TimeOfDay.now()),
                child: const Text('Now'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Pick'),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null) setState(() => _selectedTime = picked);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty && _selectedMemberId != null) {
                final takenAt = DateTime(
                  _selectedDate.year, _selectedDate.month, _selectedDate.day,
                  _selectedTime.hour, _selectedTime.minute,
                );
                // EDIT MODE
                if (widget.medicationToEdit != null) {
                  ref.read(medicationProvider.notifier).editMedication(
                    id: widget.medicationToEdit!.id,
                    name: _nameController.text,
                    familyMemberId: _selectedMemberId!,
                    type: _selectedType,
                    durationInDays: _selectedType == MedicationType.temporary ? _durationDays.toInt() : null,
                    originalStartDate: _selectedDate,
                  );
                }
                // ADD MODE
                else {
                  ref.read(medicationProvider.notifier).addMedication(
                    name: _nameController.text.trim(),
                    familyMemberId: _selectedMemberId!,
                    type: _selectedType,
                    startDate: _selectedDate,
                    durationInDays: _selectedType == MedicationType.temporary ? _durationDays.toInt() : null,
                    takenAt: takenAt,
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

