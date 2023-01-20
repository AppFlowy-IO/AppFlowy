import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:example/pages/simple_editor.dart';
import 'package:example/plugin/AI/text_robot.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_html/html.dart' as html;

enum ExportFileType {
  json,
  markdown,
  html,
  delta,
}

extension on ExportFileType {
  String get extension {
    switch (this) {
      case ExportFileType.json:
      case ExportFileType.delta:
        return 'json';
      case ExportFileType.markdown:
        return 'md';
      case ExportFileType.html:
        return 'html';
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late WidgetBuilder _widgetBuilder;
  late EditorState _editorState;
  late Future<String> _jsonString;
  ThemeData _themeData = ThemeData.light().copyWith(
    extensions: [
      ...lightEditorStyleExtension,
      ...lightPlguinStyleExtension,
    ],
  );

  @override
  void initState() {
    super.initState();

    _jsonString = rootBundle.loadString('assets/example.json');
    _widgetBuilder = (context) => SimpleEditor(
          jsonString: _jsonString,
          themeData: _themeData,
          onEditorStateChange: (editorState) {
            _editorState = editorState;
          },
        );
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

          // Text Robot
          _buildSeparator(context, 'Text Robot'),
          _buildListTile(context, 'Type Text Automatically', () async {
            final jsonString = Future<String>.value(
              jsonEncode(EditorState.empty().document.toJson()).toString(),
            );
            await _loadEditor(context, jsonString);

            Future.delayed(const Duration(seconds: 2), () {
              final textRobot = TextRobot(
                editorState: _editorState,
              );
              textRobot.insertText(
                r'''
Section 1.10.32 of "de Finibus Bonorum et Malorum", written by Cicero in 45 BC
"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?"

1914 translation by H. Rackham
"But I must explain to you how all this mistaken idea of denouncing pleasure and praising pain was born and I will give you a complete account of the system, and expound the actual teachings of the great explorer of the truth, the master-builder of human happiness. No one rejects, dislikes, or avoids pleasure itself, because it is pleasure, but because those who do not know how to pursue pleasure rationally encounter consequences that are extremely painful. Nor again is there anyone who loves or pursues or desires to obtain pain of itself, because it is pain, but because occasionally circumstances occur in which toil and pain can procure him some great pleasure. To take a trivial example, which of us ever undertakes laborious physical exercise, except to obtain some advantage from it? But who has any right to find fault with a man who chooses to enjoy a pleasure that has no annoying consequences, or one who avoids a pain that produces no resultant pleasure?"
''',
              );
            });
          }),

          // Encoder Demo
          _buildSeparator(context, 'Encoder Demo'),
          _buildListTile(context, 'Export To JSON', () {
            _exportFile(_editorState, ExportFileType.json);
          }),
          _buildListTile(context, 'Export to Markdown', () {
            _exportFile(_editorState, ExportFileType.markdown);
          }),

          // Decoder Demo
          _buildSeparator(context, 'Decoder Demo'),
          _buildListTile(context, 'Import From JSON', () {
            _importFile(ExportFileType.json);
          }),
          _buildListTile(context, 'Import From Markdown', () {
            _importFile(ExportFileType.markdown);
          }),
          _buildListTile(context, 'Import From Quill Delta', () {
            _importFile(ExportFileType.delta);
          }),

          // Theme Demo
          _buildSeparator(context, 'Theme Demo'),
          _buildListTile(context, 'Bulit In Dark Mode', () {
            _jsonString = Future<String>.value(
              jsonEncode(_editorState.document.toJson()).toString(),
            );
            setState(() {
              _themeData = ThemeData.dark().copyWith(
                extensions: [
                  ...darkEditorStyleExtension,
                  ...darkPlguinStyleExtension,
                ],
              );
            });
          }),
          _buildListTile(context, 'Custom Theme', () {
            _jsonString = Future<String>.value(
              jsonEncode(_editorState.document.toJson()).toString(),
            );
            setState(() {
              _themeData = _customizeEditorTheme(context);
            });
          }),
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

  Future<void> _loadEditor(
    BuildContext context,
    Future<String> jsonString,
  ) async {
    final completer = Completer<void>();
    _jsonString = jsonString;
    setState(
      () {
        _widgetBuilder = (context) => SimpleEditor(
              jsonString: _jsonString,
              themeData: _themeData,
              onEditorStateChange: (editorState) {
                _editorState = editorState;
              },
            );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      completer.complete();
    });
    return completer.future;
  }

  void _exportFile(
    EditorState editorState,
    ExportFileType fileType,
  ) async {
    var result = '';

    switch (fileType) {
      case ExportFileType.json:
        result = jsonEncode(editorState.document.toJson());
        break;
      case ExportFileType.markdown:
        result = documentToMarkdown(editorState.document);
        break;
      case ExportFileType.html:
      case ExportFileType.delta:
        throw UnimplementedError();
    }

    if (!kIsWeb) {
      final path = await FilePicker.platform.saveFile(
        fileName: 'document.${fileType.extension}',
      );
      if (path != null) {
        await File(path).writeAsString(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This document is saved to the $path'),
            ),
          );
        }
      }
    } else {
      final blob = html.Blob([result], 'text/plain', 'native');
      html.AnchorElement(
        href: html.Url.createObjectUrlFromBlob(blob).toString(),
      )
        ..setAttribute('download', 'document.${fileType.extension}')
        ..click();
    }
  }

  void _importFile(ExportFileType fileType) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      allowedExtensions: [fileType.extension],
      type: FileType.custom,
    );
    var plainText = '';
    if (!kIsWeb) {
      final path = result?.files.single.path;
      if (path == null) {
        return;
      }
      plainText = await File(path).readAsString();
    } else {
      final bytes = result?.files.first.bytes;
      if (bytes == null) {
        return;
      }
      plainText = const Utf8Decoder().convert(bytes);
    }

    var jsonString = '';
    switch (fileType) {
      case ExportFileType.json:
        jsonString = jsonEncode(plainText);
        break;
      case ExportFileType.markdown:
        jsonString = jsonEncode(markdownToDocument(plainText).toJson());
        break;
      case ExportFileType.delta:
        jsonString = jsonEncode(
          DeltaDocumentConvert()
              .convertFromJSON(
                jsonDecode(
                  plainText.replaceAll('\\\\\n', '\\n'),
                ),
              )
              .toJson(),
        );
        break;
      case ExportFileType.html:
        throw UnimplementedError();
    }

    if (mounted) {
      _loadEditor(context, Future<String>.value(jsonString));
    }
  }

  ThemeData _customizeEditorTheme(BuildContext context) {
    final dark = EditorStyle.dark;
    final editorStyle = dark.copyWith(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 150),
      cursorColor: Colors.blue.shade600,
      selectionColor: Colors.yellow.shade600.withOpacity(0.5),
      textStyle: GoogleFonts.poppins().copyWith(
        fontSize: 14,
        color: Colors.grey,
      ),
      placeholderTextStyle: GoogleFonts.poppins().copyWith(
        fontSize: 14,
        color: Colors.grey.shade500,
      ),
      code: dark.code?.copyWith(
        backgroundColor: Colors.lightBlue.shade200,
        fontStyle: FontStyle.italic,
      ),
      highlightColorHex: '0x60FF0000', // red
    );

    final quote = QuotedTextPluginStyle.dark.copyWith(
      textStyle: (_, __) => GoogleFonts.poppins().copyWith(
        fontSize: 14,
        color: Colors.blue.shade400,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w700,
      ),
    );

    return Theme.of(context).copyWith(extensions: [
      editorStyle,
      ...darkPlguinStyleExtension,
      quote,
    ]);
  }
}
