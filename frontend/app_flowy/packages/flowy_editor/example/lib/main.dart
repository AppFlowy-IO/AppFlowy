import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:example/expandable_floating_action_button.dart';
import 'package:example/plugin/image_node_widget.dart';
import 'package:example/plugin/youtube_link_node_widget.dart';

import 'package:flowy_editor/appflowy_editor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'AppFlowyEditor Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final editorKey = GlobalKey();
  int page = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.topCenter,
        child: _buildBody(),
      ),
      floatingActionButton: _buildExpandableFab(),
    );
  }

  Widget _buildBody() {
    if (page == 0) {
      return _buildAppFlowyEditorWithExample();
    } else if (page == 1) {
      return _buildAppFlowyEditorWithEmptyDocument();
    } else if (page == 2) {
      return _buildAppFlowyEditorWithBigDocument();
    }
    return Container();
  }

  Widget _buildExpandableFab() {
    return ExpandableFab(
      distance: 112.0,
      children: [
        ActionButton(
          onPressed: () {
            if (page == 0) return;
            setState(() {
              page = 0;
            });
          },
          icon: const Icon(Icons.note_add),
        ),
        ActionButton(
          icon: const Icon(Icons.document_scanner),
          onPressed: () {
            if (page == 1) return;
            setState(() {
              page = 1;
            });
          },
        ),
        ActionButton(
          onPressed: () {
            if (page == 2) return;
            setState(() {
              page = 2;
            });
          },
          icon: const Icon(Icons.text_fields),
        ),
      ],
    );
  }

  Widget _buildAppFlowyEditorWithEmptyDocument() {
    final editorState = EditorState.empty();
    final editor = AppFlowyEditor(
      editorState: editorState,
      keyEventHandlers: const [],
      customBuilders: const {},
    );
    return editor;
  }

  Widget _buildAppFlowyEditorWithExample() {
    return FutureBuilder<String>(
      future: rootBundle.loadString('assets/example.json'),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = Map<String, Object>.from(json.decode(snapshot.data!));
          return _buildAppFlowyEditor(EditorState(
            document: StateTree.fromJson(data),
          ));
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _buildAppFlowyEditorWithBigDocument() {
    return FutureBuilder<String>(
      future: rootBundle.loadString('assets/big_document.json'),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = Map<String, Object>.from(json.decode(snapshot.data!));
          return _buildAppFlowyEditor(EditorState(
            document: StateTree.fromJson(data),
          ));
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _buildAppFlowyEditor(EditorState editorState) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: AppFlowyEditor(
        key: editorKey,
        editorState: editorState,
        keyEventHandlers: const [],
        customBuilders: {
          'image': ImageNodeBuilder(),
          'youtube_link': YouTubeLinkNodeBuilder()
        },
      ),
    );
  }
}
