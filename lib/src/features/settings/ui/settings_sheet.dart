import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/logic/auth_provider.dart';
import '../../group/logic/group_provider.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final groupId = ref.watch(groupIdProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            user?.displayName ?? 'User',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),

          if (groupId != null)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('familyGroups')
                  .doc(groupId)
                  .get(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const CircularProgressIndicator();
                }
                final code = snap.data!.get('inviteCode') as String;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Invite code: $code',
                        style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: code)),
                    ),
                  ],
                );
              },
            ),

          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
