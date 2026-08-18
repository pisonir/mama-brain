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

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code = await createFamilyGroup(uid);
      if (mounted) setState(() => _createdCode = code);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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

    try {
      final success = await joinFamilyGroup(uid, code);
      if (!mounted) return;
      if (success) {
        // appUserProvider (StreamProvider) auto-updates when the user doc
        // changes, which navigates away from this page.
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Invalid invite code';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Setup'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                children: [
                  // Which account you're signed in as. Signing in with a
                  // different Google account is the most common reason a family
                  // "disappears", so make it obvious and easy to switch.
                  if (user != null) ...[
                    Text(
                      'Signed in as',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      user.email ?? user.displayName ?? user.uid,
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                    TextButton.icon(
                      onPressed: signOut,
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Use a different account'),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- Join family (listed first: rejoining an existing family
                  // is the common case, including recovering access) ---
                  Text(
                    'Join your family',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter the invite code from a family member who already '
                    'uses the app. Your shared history reappears once you join.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 32),

                  // --- Create family ---
                  Text(
                    'Or start a new family',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
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
