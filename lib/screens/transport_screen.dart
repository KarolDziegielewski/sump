import 'package:flutter/material.dart';

class TransportScreen extends StatelessWidget {
  const TransportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planer Podróży')),
      body: const Center(
        child: Text('Tu pojawi się planer podróży',
            style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
