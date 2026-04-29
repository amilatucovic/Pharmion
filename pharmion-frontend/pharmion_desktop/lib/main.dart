import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const PharmionApp());
}

class PharmionApp extends StatelessWidget {
  const PharmionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00BFA5)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
