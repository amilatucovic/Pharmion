import 'package:flutter/material.dart';
class ReservationDetailScreen extends StatelessWidget {
  final int id;
  const ReservationDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Reservation $id')));
}