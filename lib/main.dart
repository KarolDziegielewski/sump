import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Nowoczesny motyw M3 z lekką typografią i przytłumioną paletą
    final seed = const Color(0xFF21506B);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Płock – komunikacja',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        textTheme: Typography.blackCupertino,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        textTheme: Typography.whiteCupertino,
      ),
      home: const HomeScreen(),
    );
  }
}
