import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
import 'package:flutter/material.dart';

import 'home/home_screen.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      builder: overlayManagerBuilder,
      title: "Flowy Infra Title",
      home: HomeScreen(),
    );
  }
}
