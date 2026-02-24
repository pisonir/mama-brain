import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/family_provider.dart';

class AddFamilyDialog extends ConsumerStatefulWidget {
  const AddFamilyDialog({super.key});

  @override
  ConsumerState<AddFamilyDialog> createState() => _AddFamilyDialogState();
}

class _AddFamilyDialogState extends ConsumerState<AddFamilyDialog> {
  // --- STATE VARIABLES (the Memory) ---

  // 1. The controller: This listens to what the user types.
  late final TextEditingController _nameController;

  // 2. The Color: we default to the first color in our list
  Color _selectedColor = const Color(0xFFFFB7B2);

  // 3. The Options: A list of colors the user can pick from 
  final List<Color> _colorOptions = [
      const Color(0xFFFFB7B2),
      const Color(0xFFFFDAC1),
      const Color(0xFFE2F0CB),
      const Color(0xFFB5EAD7),
      const Color(0XFFC7CEEA),
      const Color(0XFFFDCFE8),
    ];

  @override
  void initState() {
    super.initState();
    // We initialize the text controller when the widget starts
    _nameController = TextEditingController();
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
      title: const Text("New Family Memeber"),
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
          const Text("Pick a Color:"),
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
          child: const Text("Save"),
        ),
      ],
    );
  }

  void _saveMember() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      // Access the Provider using 'ref' (available in ConsumerState)
      // We pass the name and the color value (int)
      ref.read(familyProvider.notifier).addMember(
        name: name,
        colorValue: _selectedColor.toARGB32(),
      );
      Navigator.pop(context); // Close the dialog
    }
  }

  Widget _buildColorPicker() {
    return Wrap( // Wrap arranges children in rows/cols automatically
      spacing: 8, // Gap between circles
      children: _colorOptions.map((color) {
        final isSelected = _selectedColor == color;
        return GestureDetector(
          onTap: () {
            // SET STATE: This tells Flutter "Data changed, redraw the widget!"
            setState(() {
              _selectedColor = color;
            });
          },
          child: CircleAvatar(
            backgroundColor: color,
            radius: 18,
            // If selected, show a checkmark icon. If not, show nothing (null)
            child: isSelected ? const Icon(Icons.check, color: Colors.black54) : null,
          ),
        );
      }).toList()
    );
  }
}