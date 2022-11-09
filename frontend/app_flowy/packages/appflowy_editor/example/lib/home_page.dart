import 'dart:convert';
import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:example/pages/simple_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;

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
            _loadEditor(context, jsonString);
          }),
          _buildListTile(context, 'With Empty Document', () {
            final jsonString = Future<String>.value(
              jsonEncode(EditorState.empty().document.toJson()).toString(),
            );
            _loadEditor(context, jsonString);
          }),

          // Encoder Demo
          _buildSeparator(context, 'Encoder Demo'),
          _buildListTile(context, 'Export To JSON', () {
            _exportJson(_editorState);
          }),
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

  void _loadEditor(BuildContext context, Future<String> jsonString) {
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

  void _exportJson(EditorState editorState) async {
    final document = editorState.document.toJson();
    final json = jsonEncode(document);

    if (!kIsWeb) {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export to JSON',
        fileName: 'document.json',
      );
      if (path != null) {
        await File(path).writeAsString(json);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('The document.json is saved to the $path'),
            ),
          );
        }
      }
    } else {
      final blob = html.Blob([json], 'text/plain', 'native');
      html.AnchorElement(
        href: html.Url.createObjectUrlFromBlob(blob).toString(),
      )
        ..setAttribute('download', 'document.json')
        ..click();
    }
  }

  // void _exportDocument(EditorState editorState) async {
  //   final document = editorState.document.toJson();
  //   final json = jsonEncode(document);
  //   if (kIsWeb) {
  //     final blob = html.Blob([json], 'text/plain', 'native');
  //     html.AnchorElement(
  //       href: html.Url.createObjectUrlFromBlob(blob).toString(),
  //     )
  //       ..setAttribute('download', 'editor.json')
  //       ..click();
  //   } else {
  //     final directory = await getTemporaryDirectory();
  //     final path = directory.path;
  //     final file = File('$path/editor.json');
  //     await file.writeAsString(json);

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('The document is saved to the ${file.path}'),
  //         ),
  //       );
  //     }
  //   }
  // }
}
