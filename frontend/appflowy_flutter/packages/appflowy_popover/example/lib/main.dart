import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';

import './example_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'AppFlowy Popover Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ExampleButton(
                  label: 'Left top',
                  offset: Offset(0, 10),
                  direction: PopoverDirection.bottomWithLeftAligned,
                ),
                ExampleButton(
                  label: 'Left Center',
                  offset: Offset(0, -10),
                  direction: PopoverDirection.leftWithCenterAligned,
                ),
                ExampleButton(
                  label: 'Left bottom',
                  offset: Offset(0, -10),
                  direction: PopoverDirection.topWithLeftAligned,
                ),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ExampleButton(
                    label: 'Top',
                    offset: Offset(0, 10),
                    direction: PopoverDirection.bottomWithCenterAligned,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ExampleButton(
                          label: 'Central',
                          offset: Offset(0, 10),
                          direction: PopoverDirection.bottomWithCenterAligned,
                        ),
                      ],
                    ),
                  ),
                  ExampleButton(
                    label: 'Bottom',
                    offset: Offset(0, -10),
                    direction: PopoverDirection.topWithCenterAligned,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                ExampleButton(
                  label: 'Right top',
                  offset: Offset(0, 10),
                  direction: PopoverDirection.bottomWithRightAligned,
                ),
                Expanded(child: SizedBox.shrink()),
                ExampleButton(
                  label: 'Right bottom',
                  offset: Offset(0, -10),
                  direction: PopoverDirection.topWithRightAligned,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
