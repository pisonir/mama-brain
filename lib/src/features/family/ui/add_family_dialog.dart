import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/family_member.dart';
import '../logic/family_provider.dart';
import 'family_colors.dart';

/// Dialog for creating a new family member, or — when [memberToEdit] is
/// provided — editing an existing member's name and avatar color.
class AddFamilyDialog extends ConsumerStatefulWidget {
  final FamilyMember? memberToEdit;

  const AddFamilyDialog({super.key, this.memberToEdit});

  @override
  ConsumerState<AddFamilyDialog> createState() => _AddFamilyDialogState();
}

class _AddFamilyDialogState extends ConsumerState<AddFamilyDialog> {
  // The controller: this listens to what the user types.
  late final TextEditingController _nameController;

  // The currently picked color. Defaults to the first palette color for new
  // members, or the member's existing color when editing.
  late Color _selectedColor;

  bool get _isEditing => widget.memberToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.memberToEdit?.name ?? '');
    _selectedColor = widget.memberToEdit != null
        ? Color(widget.memberToEdit!.colorValue)
        : kFamilyColorOptions.first;
  }

  @override
  void dispose() {
    // CLEANUP: Always dispose controllers to free up memory when the dialog closes
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? "Edit Family Member" : "New Family Member"),
      content: Column(
        mainAxisSize: MainAxisSize.min, // Shrink to fit content
        children: [
          // Input Field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "Name",
              hintText: "e.g. Margaux",
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Pick a Color:"),
          ),
          const SizedBox(height: 8),

          _buildColorPicker(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Close dialog
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: _saveMember,
          child: Text(_isEditing ? "Update" : "Save"),
        ),
      ],
    );
  }

  void _saveMember() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    if (_isEditing) {
      ref.read(familyProvider.notifier).editMember(
            id: widget.memberToEdit!.id,
            name: name,
            colorValue: _selectedColor.toARGB32(),
          );
    } else {
      ref.read(familyProvider.notifier).addMember(
            name: name,
            colorValue: _selectedColor.toARGB32(),
          );
    }
    Navigator.pop(context); // Close the dialog
  }

  Widget _buildColorPicker() {
    // A bounded, scrollable area so the enlarged palette never overflows the
    // dialog on small screens.
    return SizedBox(
      width: double.maxFinite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 180),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 8, // Gap between circles
            runSpacing: 8,
            children: kFamilyColorOptions.map((color) {
              final isSelected = _selectedColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () {
                  // SET STATE: tell Flutter "Data changed, redraw the widget!"
                  setState(() => _selectedColor = color);
                },
                child: CircleAvatar(
                  backgroundColor: color,
                  radius: 18,
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
