import 'dart:collection';

import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/operation/transaction_builder.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_service.dart';
import 'package:flutter/material.dart';

OverlayEntry? _videoUploadMenu;
EditorState? _editorState;
void showVideoUploadMenu(
  EditorState editorState,
  SelectionMenuService menuService,
  BuildContext context,
) {
  menuService.dismiss();

  _videoUploadMenu?.remove();
  _videoUploadMenu = OverlayEntry(builder: (context) {
    return Positioned(
      top: menuService.topLeft.dy,
      left: menuService.topLeft.dx,
      child: Material(
        child: VideoUploadMenu(
          onSubmitted: (text) {
            editorState.insertVideoNode(text);
          },
          onUpload: (text) {
            editorState.insertVideoNode(text);
          },
        ),
      ),
    );
  });

  Overlay.of(context)?.insert(_videoUploadMenu!);

  editorState.service.selectionService.currentSelection
      .addListener(_dismissVideoUploadMenu);
}

void _dismissVideoUploadMenu() {
  _videoUploadMenu?.remove();
  _videoUploadMenu = null;

  _editorState?.service.selectionService.currentSelection
      .removeListener(_dismissVideoUploadMenu);
  _editorState = null;
}

class VideoUploadMenu extends StatefulWidget {
  const VideoUploadMenu({
    Key? key,
    required this.onSubmitted,
    required this.onUpload,
  }) : super(key: key);

  final void Function(String text) onSubmitted;
  final void Function(String text) onUpload;

  @override
  State<VideoUploadMenu> createState() => _VideoUploadMenuState();
}

class _VideoUploadMenuState extends State<VideoUploadMenu> {
  final _textEditingController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            spreadRadius: 1,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16.0),
          _buildInput(),
          const SizedBox(height: 18.0),
          _buildUploadButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const Text(
      'URL Video',
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: 14.0,
        color: Colors.black,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildInput() {
    return TextField(
      focusNode: _focusNode,
      style: const TextStyle(fontSize: 14.0),
      textAlign: TextAlign.left,
      controller: _textEditingController,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: 'URL',
        hintStyle: const TextStyle(fontSize: 14.0),
        contentPadding: const EdgeInsets.all(16.0),
        isDense: true,
        suffixIcon: IconButton(
          padding: const EdgeInsets.all(4.0),
          icon: const FlowySvg(
            name: 'clear',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            _textEditingController.clear();
          },
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          borderSide: BorderSide(color: Color(0xFFBDBDBD)),
        ),
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 48,
      child: TextButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(const Color(0xFF00BCF0)),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        onPressed: () {
          widget.onUpload(_textEditingController.text);
        },
        child: const Text(
          'Upload',
          style: TextStyle(color: Colors.white, fontSize: 14.0),
        ),
      ),
    );
  }
}

extension on EditorState {
  void insertVideoNode(String src) {
    final selection = service.selectionService.currentSelection.value;
    if (selection == null) {
      return;
    }
    final videoNode = Node(
      type: 'video',
      children: LinkedList(),
      attributes: {
        'video_src': src,
        'align': 'center',
      },
    );
    TransactionBuilder(this)
      ..insertNode(
        selection.start.path,
        videoNode,
      )
      ..commit();
  }
}
