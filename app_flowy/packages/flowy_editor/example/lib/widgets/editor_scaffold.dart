import 'dart:convert';
import 'dart:io';

import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/service/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditorScaffold extends StatefulWidget {
  final String filename;

  const EditorScaffold({
    Key key,
    @required this.filename,
  }) : super(key: key);

  @override
  _EditorScaffoldState createState() => _EditorScaffoldState();
}

class _EditorScaffoldState extends State<EditorScaffold> {
  EditorController _controller;
  String _filename;
  final FocusNode _focusNode = FocusNode();

  bool _loading = false;
  String errorMsg;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null && !_loading) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = Center(child: Text('Loading...'));
    } else if (_filename != widget.filename) {
      _load();
    } else if (_controller == null) {
      body = _zeroStateView();
    } else {
      final editor = FlowyEditor(
        controller: _controller,
        focusNode: _focusNode,
        scrollable: true,
        autoFocus: false,
        expands: false,
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        readOnly: false,
        scrollBottomInset: 0,
        scrollController: ScrollController(),
      );
      body = SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: Container(
              child: editor,
            )),
            Container(
              child: FlowyToolbar.basic(
                controller: _controller,
                onImageSelectCallback: _onImageSelection,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.filename),
      ),
      body: body,
    );
  }

  Future<void> _load() async {
    _filename = widget.filename;
    try {
      final docJson = await rootBundle.loadString('assets/${widget.filename}');
      final doc = Document.fromJson(jsonDecode(docJson));
      setState(() {
        _controller = EditorController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _loading = false;
        errorMsg = error.toString();
      });
    }
  }

  Widget _zeroStateView() {
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red),
            Text('Error: ${errorMsg ?? "unknow"}'),
          ],
        ),
      ),
    );
  }

  Future<String> _onImageSelection(File file) {
    // TODO: Impl this
    return Future.value('');
  }
}
