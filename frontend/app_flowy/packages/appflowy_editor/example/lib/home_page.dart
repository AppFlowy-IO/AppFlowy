import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:example/pages/simple_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late WidgetBuilder _widgetBuilder;
  late EditorState _editorState;

  @override
  void initState() {
    super.initState();

    _widgetBuilder = (context) {
      _editorState = EditorState.empty();
      return AppFlowyEditor(editorState: EditorState.empty());
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(context),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            child: Image.asset(
              'assets/images/icon.png',
              fit: BoxFit.fill,
            ),
          ),

          // AppFlowy Editor Demo
          _buildSeparator(context, 'AppFlowy Editor Demo'),
          _buildListTile(context, 'With Example.json', () {
            final jsonString = rootBundle.loadString('assets/example.json');
            _loadJsonEditor(context, jsonString);
          }),
          _buildListTile(context, 'With Empty Document', () {
            final jsonString = Future<String>.value(
              json.encode(EditorState.empty().document.toJson()).toString(),
            );
            _loadJsonEditor(context, jsonString);
          }),

          // Encoder Demo
          _buildSeparator(context, 'Encoder Demo'),
          _buildListTile(context, 'Export To JSON', () {}),
          _buildListTile(context, 'Export to Markdown', () {}),

          // Decoder Demo
          _buildSeparator(context, 'Decoder Demo'),
          _buildListTile(context, 'Import From JSON', () {}),
          _buildListTile(context, 'Import From Markdown', () {}),

          // Theme Demo
          _buildSeparator(context, 'Theme Demo'),
          _buildListTile(context, 'Bulit In Dark Mode', () {}),
          _buildListTile(context, 'Custom Theme', () {}),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return _widgetBuilder(context);
  }

  Widget _buildListTile(
    BuildContext context,
    String text,
    VoidCallback? onTap,
  ) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 16),
      title: Text(
        text,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 14,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap?.call();
      },
    );
  }

  Widget _buildSeparator(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        _scaffoldKey.currentState?.openDrawer();
      },
      child: const Icon(Icons.menu),
    );
  }

  void _loadJsonEditor(BuildContext context, Future<String> jsonString) {
    setState(
      () {
        _widgetBuilder = (context) => SimpleEditor(
              jsonString: jsonString,
              onEditorStateChange: (editorState) {
                _editorState = editorState;
              },
            );
      },
    );
  }
}
