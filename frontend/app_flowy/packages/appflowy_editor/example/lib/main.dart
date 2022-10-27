import 'dart:convert';
import 'dart:io';

import 'package:example/plugin/editor_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:example/plugin/code_block_node_widget.dart';
import 'package:example/plugin/horizontal_rule_node_widget.dart';
import 'package:example/plugin/tex_block_node_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

import 'package:appflowy_editor/appflowy_editor.dart';

import 'expandable_floating_action_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        AppFlowyEditorLocalizations.delegate,
      ],
      supportedLocales: [Locale('en', 'US')],
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'AppFlowyEditor Example'),
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
  EditorState? _editorState;
  bool darkMode = false;
  Future<String>? _jsonString;

  ThemeData? _editorThemeData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: _buildEditor(context),
      floatingActionButton: _buildExpandableFab(),
    );
  }

  Widget _buildEditor(BuildContext context) {
    if (_jsonString != null) {
      return _buildEditorWithJsonString(_jsonString!);
    }
    if (_pageIndex == 0) {
      return _buildEditorWithJsonString(
        rootBundle.loadString('assets/example.json'),
      );
    } else if (_pageIndex == 1) {
      return _buildEditorWithJsonString(
        Future.value(
          jsonEncode(EditorState.empty().document.toJson()),
        ),
      );
    }
    throw UnimplementedError();
  }

  Widget _buildEditorWithJsonString(Future<String> jsonString) {
    return FutureBuilder<String>(
      future: jsonString,
      builder: (_, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          _editorState ??= EditorState(
            document: Document.fromJson(
              Map<String, Object>.from(
                json.decode(snapshot.data!),
              ),
            ),
          );
          _editorState!.logConfiguration
            ..level = LogLevel.all
            ..handler = (message) {
              debugPrint(message);
            };
          _editorState!.transactionStream.listen((event) {
            debugPrint('Transaction: ${event.toJson()}');
          });
          _editorThemeData ??= Theme.of(context).copyWith(extensions: [
            if (darkMode) ...darkEditorStyleExtension,
            if (darkMode) ...darkPlguinStyleExtension,
            if (!darkMode) ...lightEditorStyleExtension,
            if (!darkMode) ...lightPlguinStyleExtension,
          ]);
          return Container(
            color: darkMode ? Colors.black : Colors.white,
            width: MediaQuery.of(context).size.width,
            child: AppFlowyEditor(
              editorState: _editorState!,
              editable: true,
              themeData: _editorThemeData,
              customBuilders: {
                'text/code_block': CodeBlockNodeWidgetBuilder(),
                'tex': TeXBlockNodeWidgetBuidler(),
                'horizontal_rule': HorizontalRuleWidgetBuilder(),
              },
              shortcutEvents: [
                enterInCodeBlock,
                ignoreKeysInCodeBlock,
                insertHorizontalRule,
              ],
              selectionMenuItems: [
                codeBlockMenuItem,
                teXBlockMenuItem,
                horizontalRuleMenuItem,
              ],
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
          icon: const Icon(Icons.print),
          onPressed: () => _exportDocument(_editorState!),
        ),
        ActionButton(
          icon: const Icon(Icons.import_export),
          onPressed: () async => await _importDocument(),
        ),
        ActionButton(
          icon: const Icon(Icons.dark_mode),
          onPressed: () {
            setState(() {
              darkMode = !darkMode;
            });
          },
        ),
        ActionButton(
          icon: const Icon(Icons.color_lens),
          onPressed: () {
            setState(() {
              _editorThemeData = customizeEditorTheme(context);
              darkMode = true;
            });
          },
        ),
      ],
    );
  }

  void _exportDocument(EditorState editorState) async {
    final document = editorState.document.toJson();
    final json = jsonEncode(document);
    if (kIsWeb) {
      final blob = html.Blob([json], 'text/plain', 'native');
      html.AnchorElement(
        href: html.Url.createObjectUrlFromBlob(blob).toString(),
      )
        ..setAttribute('download', 'editor.json')
        ..click();
    } else {
      final directory = await getTemporaryDirectory();
      final path = directory.path;
      final file = File('$path/editor.json');
      await file.writeAsString(json);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('The document is saved to the ${file.path}'),
          ),
        );
      }
    }
  }

  Future<void> _importDocument() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        allowedExtensions: ['json'],
        type: FileType.custom,
      );
      final bytes = result?.files.first.bytes;
      if (bytes != null) {
        final jsonString = const Utf8Decoder().convert(bytes);
        setState(() {
          _editorState = null;
          _jsonString = Future.value(jsonString);
        });
      }
    } else {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/editor.json';
      final file = File(path);
      setState(() {
        _editorState = null;
        _jsonString = file.readAsString();
      });
    }
  }

  void _switchToPage(int pageIndex) {
    if (pageIndex != _pageIndex) {
      setState(() {
        _editorThemeData = null;
        _editorState = null;
        _pageIndex = pageIndex;
      });
    }
  }
}
