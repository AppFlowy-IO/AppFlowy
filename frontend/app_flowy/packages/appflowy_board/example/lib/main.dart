import 'package:flutter/material.dart';
import 'single_board_list_example.dart';
import 'multi_board_list_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;
  final _bottomNavigationColor = Colors.blue;

  final List<Widget> _examples = [
    const MultiBoardListExample(),
    const SingleBoardListExample(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('AppFlowy Board'),
          ),
          body: _examples[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            fixedColor: _bottomNavigationColor,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            currentIndex: _currentIndex,
            items: [
              BottomNavigationBarItem(
                  icon: Icon(Icons.grid_on, color: _bottomNavigationColor),
                  label: "MultiColumn"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.grid_on, color: _bottomNavigationColor),
                  label: "SingleColumn"),
            ],
            onTap: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
          )),
    );
  }
}
