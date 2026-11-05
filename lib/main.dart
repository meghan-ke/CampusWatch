// lib/main.dart
// Entry point of CampusWatch.
// Responsibility: initialise Firebase, then start the app.
// All app logic lives in app.dart and the folders under lib/.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Required before using any plugin (like Firebase) before runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // Connects the app to our Firebase project using the generated options.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const App());
}
