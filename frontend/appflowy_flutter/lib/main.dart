// The original content is temporarily commented out to allow generating a self-contained demo - feel free to uncomment later.

// import 'package:scaled_app/scaled_app.dart';
//
// import 'startup/startup.dart';
//
// Future<void> main() async {
//   ScaledWidgetsFlutterBinding.ensureInitialized(
//     scaleFactor: (_) => 1.0,
//   );
//
//   await runAppFlowy();
// }
//

import 'package:flutter/material.dart';
import 'package:appflowy/src/rust/api/simple.dart';
import 'package:appflowy/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
        body: Center(
          child: Text(
            'Action: Call Rust `greet("Tom")`\nResult: `${greet(name: "Tom")}`',
          ),
        ),
      ),
    );
  }
}
