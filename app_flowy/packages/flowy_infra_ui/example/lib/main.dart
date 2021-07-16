import 'package:flutter/material.dart';
import '../home/home_screen.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return const MaterialApp();
=======
    return const MaterialApp(
      title: "Flowy Infra Title",
      home: HomeScreen(),
    );
>>>>>>> [infra_ui][keyboard] (WIP) Add demo proj for infra ui
  }
}
