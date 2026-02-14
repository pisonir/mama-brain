import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/logic/auth_provider.dart';
import 'features/auth/ui/login_page.dart';
import 'features/group/logic/group_provider.dart';
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
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => const LoginPage(),
        data: (user) {
          if (user == null) return const LoginPage();

          // User is signed in — check if they have a group
          final groupId = ref.watch(groupIdProvider);

          // appUserProvider is a FutureProvider; while it loads, show spinner
          final appUser = ref.watch(appUserProvider);
          return appUser.when(
            loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator())),
            error: (_, _) => const LoginPage(),
            data: (appUserData) {
              if (appUserData == null) return const LoginPage();
              if (groupId == null) return const GroupSetupPage();
              return const MainScreen();
            },
          );
        },
      ),
    );
  }
}
