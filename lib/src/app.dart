import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/logic/auth_provider.dart';
import 'features/auth/ui/login_page.dart';
import 'features/group/ui/group_setup_page.dart';
import 'main_screen.dart';

class MamaBrainApp extends ConsumerWidget {
  const MamaBrainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Mama Brain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when(
        loading: () => const _LoadingScreen(),
        error: (_, _) => const LoginPage(),
        data: (user) {
          // Signed out — the only case that should ever show the login screen.
          if (user == null) return const LoginPage();

          // From here on the Firebase session is valid and persisted, so we
          // never fall back to LoginPage: doing that is what made the app ask
          // for a fresh sign-in on every launch whenever Firestore was slow,
          // offline, or the profile doc was missing.
          final appUser = ref.watch(appUserProvider);
          return appUser.when(
            loading: () => const _LoadingScreen(),
            // Profile couldn't be read (offline with a cold cache, transient
            // Firestore error). The session is still good — offer a retry
            // instead of throwing the user back to sign-in.
            error: (error, _) => _ProfileErrorScreen(
              error: error,
              onRetry: () => ref.invalidate(appUserProvider),
            ),
            data: (appUserData) {
              // Doc missing: appUserProvider is recreating it, so wait rather
              // than bouncing to login.
              if (appUserData == null) return const _LoadingScreen();
              if (appUserData.groupId == null) return const GroupSetupPage();
              return const MainScreen();
            },
          );
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Shown when the signed-in user's profile can't be loaded. Keeps the session
/// intact and offers a retry, with sign-out only as a deliberate escape hatch.
class _ProfileErrorScreen extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ProfileErrorScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "Couldn't load your profile",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'You are still signed in. Check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: signOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
