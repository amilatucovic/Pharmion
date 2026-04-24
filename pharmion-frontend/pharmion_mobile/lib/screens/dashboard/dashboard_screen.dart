import 'package:flutter/material.dart';
class DashboardScreen extends StatelessWidget {
  final Widget child;
  const DashboardScreen({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}
class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Dashboard')));
}