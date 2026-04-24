import 'package:flutter/material.dart';
class PrescriptionDetailScreen extends StatelessWidget {
  final int id;
  const PrescriptionDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Prescription $id')));
}