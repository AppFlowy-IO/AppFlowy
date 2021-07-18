import 'package:flutter/material.dart';
import 'home/home_screen.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Flowy Infra Title",
      home: HomeScreen(),
    );
  }
}
