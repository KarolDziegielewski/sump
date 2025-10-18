import 'package:flutter/material.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rozkłady jazdy')),
      body: const Center(
        child: Text('Tu pojawią się rozkłady jazdy',
            style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
