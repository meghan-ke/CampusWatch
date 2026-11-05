// lib/app.dart
// Root widget of CampusWatch: applies the theme, registers the providers
// (app-wide state) and decides which page to show via AuthGate.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'screens/home_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/login_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider makes each provider available to every screen below it.
    // IncidentProvider will be added here in Step 5.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // IncidentProvider follows the signed-in user: it starts listening
        // to Firestore at login and stops at logout.
        ChangeNotifierProxyProvider<AuthProvider, IncidentProvider>(
          create: (_) => IncidentProvider(),
          update: (_, auth, incidents) => incidents!..bindUser(auth.needsVerification ? null : auth.user),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}

/// Chooses the first page based on the sign-in state.
/// It rebuilds whenever AuthProvider changes, so login and logout switch
/// pages automatically.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Still checking whether a previous session exists.
    if (auth.isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isLoggedIn) return const LoginScreen();
    if (auth.needsVerification) return const VerifyEmailScreen();
    return const HomeScreen();
  }
}