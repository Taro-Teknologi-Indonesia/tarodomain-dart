import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../core/api.dart';
import '../theme.dart';

/// The organizer's sign-in before creating an auction (X6).
///
/// It doesn't navigate on success: signing in changes the auth state, and
/// the router's `/sign-in` redirect then opens where the organizer was
/// going.
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: const Text('Sign in to create an auction'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Only organizers sign in. Bidders never need an account.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Brand.muted,
                  ),
                ),
                const SizedBox(height: 24),
                SignInWidget(
                  client: client,
                  onError: (error) =>
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sign-in failed: $error')),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
