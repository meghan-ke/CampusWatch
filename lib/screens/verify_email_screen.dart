// lib/screens/verify_email_screen.dart
// Shown to a signed-in student whose email is not verified yet.
// AuthGate (app.dart) swaps this screen for the home page as soon as
// AuthProvider reports the email as verified.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/primary_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    final verified = await context.read<AuthProvider>().checkVerified();
    if (!mounted) return;
    setState(() => _checking = false);

    // If verified, AuthGate has already replaced this screen.
    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not verified yet. Open the link in the email first.'),
        ),
      );
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final sent = await auth.resendVerification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? 'Verification email sent.'
              : auth.errorMessage ?? 'Could not send the email.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.user?.email ?? '';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Verify your email',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a verification link to\n$email\n\n'
                  'Open it, then come back and tap the button below. '
                  'Check your spam folder if you cannot find it.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: "I've verified my email",
                  icon: Icons.check_circle_outline,
                  isLoading: _checking,
                  onPressed: _check,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _checking ? null : _resend,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Resend email'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  child: const Text('Use a different account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}