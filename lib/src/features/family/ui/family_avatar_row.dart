import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mama_brain/src/core/models/family_member.dart';
import '../logic/family_provider.dart';
import 'add_family_dialog.dart';

class FamilyAvatarRow extends ConsumerWidget {
  const FamilyAvatarRow({super.key});

  Widget _buildMemberAvatar(FamilyMember member) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      // margin: const EdgeInsets.only(left: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center vertically
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyMembers = ref.watch(familyProvider);

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: familyMembers.length + 1, // Members + Add button
        itemBuilder: (context, index) {
          if (index == familyMembers.length) {
            return _buildAddButton(context);
          }

          final member = familyMembers[index];
          return _buildMemberAvatar(member);
        },
      ),
    );
  }
}
