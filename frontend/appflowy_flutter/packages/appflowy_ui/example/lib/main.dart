import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:appflowy_ui_example/src/buttons/buttons_page.dart';
import 'package:appflowy_ui_example/src/textfield/textfield_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFlowyTheme(
      data: AppFlowyThemeData.light(),
      child: MaterialApp(
        title: 'AppFlowy UI Example',
        home: const MyHomePage(
          title: 'AppFlowy UI',
        ),
      ),
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
  final tabs = [
    Tab(text: 'Button'),
    Tab(text: 'TextField'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(
            widget.title,
            style: theme.textStyle.title.enhanced(
              color: theme.textColorScheme.primary,
            ),
          ),
        ),
        body: TabBarView(
          children: [
            ButtonsPage(),
            TextFieldPage(),
          ],
        ),
        bottomNavigationBar: TabBar(
          tabs: tabs,
        ),
      ),
    );
  }
}
