import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:path_provider/path_provider.dart';

import 'package:appflowy_editor/appflowy_editor.dart';

import 'expandable_floating_action_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'AppFlowyEditor Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _pageIndex = 0;
  late EditorState _editorState;
  Future<String>? _jsonString;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.topCenter,
        child: _buildEditor(context),
      ),
      floatingActionButton: _buildExpandableFab(),
    );
  }

  Widget _buildEditor(BuildContext context) {
    if (_jsonString != null) {
      return _buildEditorWithJsonPath(_jsonString!);
    }
    if (_pageIndex == 0) {
      return _buildEditorWithJsonPath(
          rootBundle.loadString('assets/example.json'));
    } else if (_pageIndex == 1) {
      return _buildEditorWithJsonPath(
          rootBundle.loadString('assets/big_document.json'));
    } else if (_pageIndex == 2) {
      return _buildEditorWithEmptyDocument();
    }
    throw UnimplementedError();
  }

  Widget _buildEditorWithJsonPath(Future<String> jsonString) {
    return FutureBuilder<String>(
      future: jsonString,
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          _editorState = EditorState(
            document: StateTree.fromJson(
              Map<String, Object>.from(
                json.decode(snapshot.data!),
              ),
            ),
          );
          _editorState.logConfiguration
            ..level = LogLevel.all
            ..handler = (message) {
              debugPrint(message);
            };
          return Container(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: AppFlowyEditor(
              editorState: _editorState,
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _buildEditorWithEmptyDocument() {
    _editorState = EditorState.empty();
    _editorState.logConfiguration
      ..level = LogLevel.all
      ..handler = (message) {
        debugPrint(message);
      };
    final editor = AppFlowyEditor(
      editorState: _editorState,
    );
    return editor;
  }

  Widget _buildExpandableFab() {
    return ExpandableFab(
      distance: 112.0,
      children: [
        ActionButton(
          icon: const Icon(Icons.abc),
          onPressed: () => _switchToPage(0),
        ),
        ActionButton(
          icon: const Icon(Icons.abc),
          onPressed: () => _switchToPage(1),
        ),
        ActionButton(
          icon: const Icon(Icons.abc),
          onPressed: () => _switchToPage(2),
        ),
        ActionButton(
          icon: const Icon(Icons.print),
          onPressed: () => _exportDocument(_editorState),
        ),
        ActionButton(
          icon: const Icon(Icons.import_export),
          onPressed: () => _importDocument(),
        ),
      ],
    );
  }

  void _exportDocument(EditorState editorState) async {
    final document = editorState.document.toJson();
    final json = jsonEncode(document);
    final directory = await getTemporaryDirectory();
    final path = directory.path;
    final file = File('$path/editor.json');
    await file.writeAsString(json);
  }

  void _importDocument() async {
    final directory = await getTemporaryDirectory();
    final path = directory.path;
    final file = File('$path/editor.json');
    setState(() {
      _jsonString = file.readAsString();
    });
  }

  void _switchToPage(int pageIndex) {
    if (pageIndex != _pageIndex) {
      setState(() {
        _pageIndex = pageIndex;
      });
    }
  }
}
