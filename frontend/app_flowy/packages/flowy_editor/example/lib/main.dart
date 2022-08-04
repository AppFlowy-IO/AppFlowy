import 'dart:convert';

import 'package:example/expandable_floating_action_button.dart';
import 'package:example/plugin/image_node_widget.dart';
import 'package:flutter/material.dart';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
      home: const MyHomePage(title: 'FlowyEditor Example'),
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
  late EditorState _editorState;
  final editorKey = GlobalKey();
  int page = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: _buildBody(),
      floatingActionButton: ExpandableFab(
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
            onPressed: () {
              if (page == 1) return;
              setState(() {
                page = 1;
              });
            },
            icon: const Icon(Icons.text_fields),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (page == 0) {
      return _buildFlowyEditor();
    } else if (page == 1) {
      return _buildTextField();
    }
    return Container();
  }

  Widget _buildFlowyEditor() {
    return FutureBuilder<String>(
      future: rootBundle.loadString('assets/example.json'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          final data = Map<String, Object>.from(json.decode(snapshot.data!));
          final document = StateTree.fromJson(data);
          _editorState = EditorState(
            document: document,
          );
          return Container(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: FlowyEditor(
              key: editorKey,
              editorState: _editorState,
              keyEventHandlers: const [],
              customBuilders: {
                'image': ImageNodeBuilder(),
              },
            ),
            // shortcuts: [
            //   // TODO: this won't work, just a example for now.
            //   {
            //     'h1': (editorState, eventName) {
            //       debugPrint('shortcut => $eventName');
            //       final selectedNodes = editorState.selectedNodes;
            //       if (selectedNodes.isEmpty) {
            //         return;
            //       }
            //       final textNode = selectedNodes.first as TextNode;
            //       TransactionBuilder(editorState)
            //         ..formatText(textNode, 0, textNode.toRawString().length, {
            //           'heading': 'h1',
            //         })
            //         ..commit();
            //     }
            //   },
            //   {
            //     'bold': (editorState, eventName) =>
            //         debugPrint('shortcut => $eventName')
            //   },
            //   {
            //     'underline': (editorState, eventName) =>
            //         debugPrint('shortcut => $eventName')
            //   },
            // ],
          );
        }
      },
    );
  }

  Widget _buildTextField() {
    return const Center(
      child: TextField(),
    );
  }
}
