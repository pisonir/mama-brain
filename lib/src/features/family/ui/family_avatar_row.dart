import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mama_brain/src/core/models/family_member.dart';
import '../../medications/logic/medication_provider.dart';
import '../../symptoms/logic/symptom_provider.dart';
import '../logic/family_provider.dart';
import 'add_family_dialog.dart';

class FamilyAvatarRow extends ConsumerWidget {
  const FamilyAvatarRow({super.key});

  Widget _buildMemberAvatar(BuildContext context, WidgetRef ref,
      FamilyMember member) {
    // Tap opens a manage menu (edit / delete); long-press starts a drag to
    // reorder (wired up by the ReorderableDelayedDragStartListener wrapper).
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: GestureDetector(
        onTap: () => _showMemberMenu(context, ref, member),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Color(member.colorValue),
              child: Text(
                member.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(member.name, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(9),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const AddFamilyDialog(),
              );
            },
            // We give the InkWell a border radius so the ripple is round, not square
            borderRadius: BorderRadius.circular(30),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.add, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 4),
          const Text("Add", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // Manage sheet shown when tapping a member: edit their name/color, or delete
  // them (which cascade-deletes their medications and symptoms).
  void _showMemberMenu(BuildContext context, WidgetRef ref, FamilyMember member) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(member.colorValue),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      member.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit name & color'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showDialog(
                    context: context,
                    builder: (_) => AddFamilyDialog(memberToEdit: member),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete member',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDelete(context, ref, member);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, FamilyMember member) {
    // Count what will be cascade-deleted so the warning is concrete.
    final medCount = ref
        .read(medicationProvider)
        .where((m) => m.familyMemberId == member.id)
        .length;
    final symptomCount = ref
        .read(symptomProvider)
        .where((s) => s.familyMemberId == member.id)
        .length;

    final parts = <String>[
      if (medCount > 0) '$medCount medication${medCount == 1 ? '' : 's'}',
      if (symptomCount > 0)
        '$symptomCount symptom${symptomCount == 1 ? '' : 's'}',
    ];
    final detail = parts.isEmpty
        ? "This member has no logged entries."
        : "This will also permanently delete ${parts.join(' and ')} logged for ${member.name}.";

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Delete ${member.name}?"),
          content: Text("$detail\n\nThis cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(familyProvider.notifier).deleteMember(member.id);
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyMembers = ref.watch(familyProvider);

    return SizedBox(
      height: 100,
      child: Row(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              // We drive dragging via a long-press wrapper instead of the
              // default handles, so a normal tap still opens the manage menu.
              buildDefaultDragHandles: false,
              itemCount: familyMembers.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;
                ref
                    .read(familyProvider.notifier)
                    .reorderMembers(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final member = familyMembers[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(member.id),
                  index: index,
                  child: _buildMemberAvatar(context, ref, member),
                );
              },
            ),
          ),
          _buildAddButton(context),
        ],
      ),
    );
  }
}
