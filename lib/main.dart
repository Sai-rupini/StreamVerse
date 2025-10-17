import 'package:flutter/material.dart';
import 'package:movie/screens/splash_screen.dart';

void main() {
  runApp(const StreamVerseApp());
}

class StreamVerseApp extends StatelessWidget {
  const StreamVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreamVerse',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFF141414),
      ),
      home: const SplashScreen(),
    );
  }
}
