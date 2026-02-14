import 'package:flutter/material.dart';
import '../logic/auth_provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.child_care,
                size: 96,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Mama Brain',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () => signInWithGoogle(),
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
