import 'dart:collection';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

SelectionMenuItem teXBlockMenuItem = SelectionMenuItem(
  name: () => 'Tex',
  icon: (_, __) => const Icon(
    Icons.text_fields_rounded,
    color: Colors.black,
    size: 18.0,
  ),
  keywords: ['tex, latex, katex'],
  handler: (editorState, _, __) {
    final selection =
        editorState.service.selectionService.currentSelection.value;
    final textNodes = editorState.service.selectionService.currentSelectedNodes
        .whereType<TextNode>();
    if (selection == null || !selection.isCollapsed || textNodes.isEmpty) {
      return;
    }
    final Path texNodePath;
    if (textNodes.first.toPlainText().isEmpty) {
      texNodePath = selection.end.path;
      final transaction = editorState.transaction
        ..insertNode(
          selection.end.path,
          Node(
            type: 'tex',
            children: LinkedList(),
            attributes: {'tex': ''},
          ),
        )
        ..deleteNode(textNodes.first)
        ..afterSelection = selection;
      editorState.apply(transaction);
    } else {
      texNodePath = selection.end.path.next;
      final transaction = editorState.transaction
        ..insertNode(
          selection.end.path.next,
          Node(
            type: 'tex',
            children: LinkedList(),
            attributes: {'tex': ''},
          ),
        )
        ..afterSelection = selection;
      editorState.apply(transaction);
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final texState =
          editorState.document.nodeAtPath(texNodePath)?.key?.currentState;
      if (texState != null && texState is __TeXBlockNodeWidgetState) {
        texState.showEditingDialog();
      }
    });
  },
);

class TeXBlockNodeWidgetBuidler extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _TeXBlockNodeWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return node.attributes['tex'] is String;
      };
}

class _TeXBlockNodeWidget extends StatefulWidget {
  const _TeXBlockNodeWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;

  @override
  State<_TeXBlockNodeWidget> createState() => __TeXBlockNodeWidgetState();
}

class __TeXBlockNodeWidgetState extends State<_TeXBlockNodeWidget> {
  String get _tex => widget.node.attributes['tex'] as String;
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onHover: (value) {
        setState(() {
          _isHover = value;
        });
      },
      onTap: () {
        showEditingDialog();
      },
      child: Stack(
        children: [
          _buildTex(context),
          if (_isHover) _buildDeleteButton(context),
        ],
      ),
    );
  }

  Widget _buildTex(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        color: _isHover ? Colors.grey[200] : Colors.transparent,
      ),
      child: Center(
        child: Math.tex(
          _tex,
          textStyle: const TextStyle(fontSize: 20),
          mathStyle: MathStyle.display,
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return Positioned(
      top: -5,
      right: -5,
      child: IconButton(
        icon: Icon(
          Icons.delete_outline,
          color: Colors.blue[400],
          size: 16,
        ),
        onPressed: () {
          final transaction = widget.editorState.transaction
            ..deleteNode(widget.node);
          widget.editorState.apply(transaction);
        },
      ),
    );
  }

  void showEditingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _tex);
        return AlertDialog(
          title: const Text('Edit Katex'),
          content: TextField(
            controller: controller,
            maxLines: null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (controller.text != _tex) {
                  final transaction = widget.editorState.transaction
                    ..updateNode(
                      widget.node,
                      {'tex': controller.text},
                    );
                  widget.editorState.apply(transaction);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
