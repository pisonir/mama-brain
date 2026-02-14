import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/logic/auth_provider.dart';
import '../logic/group_provider.dart';

class GroupSetupPage extends ConsumerStatefulWidget {
  const GroupSetupPage({super.key});

  @override
  ConsumerState<GroupSetupPage> createState() => _GroupSetupPageState();
}

class _GroupSetupPageState extends ConsumerState<GroupSetupPage> {
  String? _createdCode;
  final _joinController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _joinController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _loading = true);
    try {
      await createFamilyGroup(uid);
      // Re-read user doc to get the new groupId
      ref.invalidate(appUserProvider);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinGroup() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    final code = _joinController.text.trim().toUpperCase();
    if (uid == null || code.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await joinFamilyGroup(uid, code);
    if (!mounted) return;

    if (success) {
      ref.invalidate(appUserProvider);
    } else {
      setState(() {
        _loading = false;
        _error = 'Invalid invite code';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Setup'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Create family ---
                  FilledButton.icon(
                    onPressed: _createGroup,
                    icon: const Icon(Icons.group_add),
                    label: const Text('Create Family'),
                  ),

                  if (_createdCode != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Code: $_createdCode',
                            style: Theme.of(context).textTheme.titleMedium),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => Clipboard.setData(
                              ClipboardData(text: _createdCode!)),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 32),

                  // --- Join family ---
                  Text('Or join an existing family',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _joinController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Invite Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _joinGroup,
                    icon: const Icon(Icons.login),
                    label: const Text('Join Family'),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
      ),
    );
  }
}
