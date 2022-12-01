import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';

const String kMathEquationType = 'math_equation';
const String kMathEquationAttr = 'math_equation';

// TODO: l10n
SelectionMenuItem mathEquationMenuItem = SelectionMenuItem(
  name: () => 'Math Equation',
  icon: (editorState, onSelected) => Icon(
    Icons.text_fields_rounded,
    color: onSelected
        ? editorState.editorStyle.selectionMenuItemSelectedIconColor
        : editorState.editorStyle.selectionMenuItemIconColor,
    size: 18.0,
  ),
  keywords: ['tex, latex, katex', 'math equation'],
  handler: (editorState, _, __) {
    final selection =
        editorState.service.selectionService.currentSelection.value;
    final textNodes = editorState.service.selectionService.currentSelectedNodes
        .whereType<TextNode>();
    if (selection == null || textNodes.isEmpty) {
      return;
    }
    final textNode = textNodes.first;
    final Path mathEquationNodePath;
    if (textNode.toPlainText().isEmpty) {
      mathEquationNodePath = selection.end.path;
    } else {
      mathEquationNodePath = selection.end.path.next;
    }
    // insert the math equation node
    final transaction = editorState.transaction
      ..insertNode(
        mathEquationNodePath,
        Node(type: kMathEquationType, attributes: {kMathEquationAttr: ''}),
      )
      ..afterSelection = selection;
    editorState.apply(transaction);

    // tricy to show the editing dialog.
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final mathEquationState = editorState.document
          .nodeAtPath(mathEquationNodePath)
          ?.key
          ?.currentState;
      if (mathEquationState != null &&
          mathEquationState is _MathEquationNodeWidgetState) {
        mathEquationState.showEditingDialog();
      }
    });
  },
);

class MathEquationNodeWidgetBuidler extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _MathEquationNodeWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator =>
      (node) => node.attributes[kMathEquationAttr] is String;
}

class _MathEquationNodeWidget extends StatefulWidget {
  const _MathEquationNodeWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;

  @override
  State<_MathEquationNodeWidget> createState() =>
      _MathEquationNodeWidgetState();
}

class _MathEquationNodeWidgetState extends State<_MathEquationNodeWidget> {
  String get _mathEquation =>
      widget.node.attributes[kMathEquationAttr] as String;
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
          _buildMathEquation(context),
          if (_isHover) _buildDeleteButton(context),
        ],
      ),
    );
  }

  Widget _buildMathEquation(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        color: _isHover ? Colors.grey[200] : Colors.transparent,
      ),
      child: Center(
        child: Math.tex(
          _mathEquation,
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
          Icons.delete_forever_outlined,
          color: widget.editorState.editorStyle.selectionMenuItemIconColor,
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
        final controller = TextEditingController(text: _mathEquation);
        return AlertDialog(
          title: const Text('Edit Math Equation'),
          content: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (key) {
              if (key is! RawKeyDownEvent) return;
              if (key.logicalKey == LogicalKeyboardKey.enter &&
                  !key.isShiftPressed) {
                _updateMathEquation(controller.text);
              } else if (key.logicalKey == LogicalKeyboardKey.escape) {
                _dismiss();
              }
            },
            child: TextField(
              autofocus: true,
              controller: controller,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'E = MC^2',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _dismiss(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _updateMathEquation(controller.text),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _updateMathEquation(String mathEquation) {
    _dismiss();
    if (mathEquation == _mathEquation) {
      return;
    }
    final transaction = widget.editorState.transaction;
    transaction.updateNode(
      widget.node,
      {
        kMathEquationAttr: mathEquation,
      },
    );
    widget.editorState.apply(transaction);
  }

  void _dismiss() {
    Navigator.of(context).pop();
  }
}
