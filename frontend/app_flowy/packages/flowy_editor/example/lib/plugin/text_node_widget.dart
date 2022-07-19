import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flowy_editor/document/text_delta.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';

class TextNodeBuilder extends NodeWidgetBuilder {
  TextNodeBuilder.create({
    required super.node,
    required super.editorState,
  }) : super.create() {
    nodeValidator = ((node) {
      return node.type == 'text';
    });
  }

  @override
  Widget build(BuildContext buildContext) {
    return _TextNodeWidget(node: node, editorState: editorState);
  }
}

extension on Attributes {
  TextStyle toTextStyle() {
    return TextStyle(
      color: this['color'] != null ? Colors.red : Colors.black,
      fontSize: this['font-size'] != null ? 30 : 15,
    );
  }
}

TextSpan _textInsertToTextSpan(TextInsert textInsert) {
  FontWeight? fontWeight;
  FontStyle? fontStyle;
  TextDecoration? decoration;
  GestureRecognizer? gestureRecognizer;
  Color? color;
  final attributes = textInsert.attributes;
  if (attributes?['bold'] == true) {
    fontWeight = FontWeight.bold;
  }
  if (attributes?['italic'] == true) {
    fontStyle = FontStyle.italic;
  }
  if (attributes?["underline"] == true) {
    decoration = TextDecoration.underline;
  }
  if (attributes?["href"] is String) {
    color = const Color.fromARGB(255, 55, 120, 245);
    decoration = TextDecoration.underline;
    gestureRecognizer = TapGestureRecognizer()
      ..onTap = () {
        // TODO: open the link
      };
  }
  return TextSpan(
      text: textInsert.content,
      style: TextStyle(
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        decoration: decoration,
        color: color,
      ),
      recognizer: gestureRecognizer);
}

extension on TextNode {
  List<TextSpan> toTextSpans() {
    final result = <TextSpan>[];

    for (final op in delta.operations) {
      if (op is TextInsert) {
        result.add(_textInsertToTextSpan(op));
      }
    }

    return result;
  }
}

TextSelection? _globalSelectionToLocal(Node node, Selection? globalSel) {
  if (globalSel == null) {
    return null;
  }
  final nodePath = node.path;

  if (!pathEquals(nodePath, globalSel.start.path)) {
    return null;
  }
  if (globalSel.isCollapsed()) {
    return TextSelection(
        baseOffset: globalSel.start.offset, extentOffset: globalSel.end.offset);
  } else {
    if (pathEquals(globalSel.start.path, globalSel.end.path)) {
      return TextSelection(
          baseOffset: globalSel.start.offset,
          extentOffset: globalSel.end.offset);
    }
  }
  return null;
}

Selection? _localSelectionToGlobal(Node node, TextSelection? sel) {
  if (sel == null) {
    return null;
  }
  final nodePath = node.path;

  return Selection(
    start: Position(path: nodePath, offset: sel.baseOffset),
    end: Position(path: nodePath, offset: sel.extentOffset),
  );
}

class _TextNodeWidget extends StatefulWidget {
  final Node node;
  final EditorState editorState;

  const _TextNodeWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  @override
  State<_TextNodeWidget> createState() => __TextNodeWidgetState();
}

String _textContentOfDelta(Delta delta) {
  return delta.operations.fold("", (previousValue, element) {
    if (element is TextInsert) {
      return previousValue + element.content;
    }
    return previousValue;
  });
}

class __TextNodeWidgetState extends State<_TextNodeWidget>
    implements DeltaTextInputClient {
  final _focusNode = FocusNode(debugLabel: "input");
  TextNode get node => widget.node as TextNode;
  EditorState get editorState => widget.editorState;

  TextEditingValue get textEditingValue => TextEditingValue(
        text: node.toRawString(),
      );

  TextInputConnection? _textInputConnection;

  _backDeleteTextAtSelection(TextSelection? sel) {
    if (sel == null) {
      return;
    }
    if (sel.start == 0) {
      return;
    }

    if (sel.isCollapsed) {
      TransactionBuilder(editorState)
        ..deleteText(node, sel.start - 1, 1)
        ..commit();
    } else {
      TransactionBuilder(editorState)
        ..deleteText(node, sel.start, sel.extentOffset - sel.baseOffset)
        ..commit();
    }

    _setEditingStateFromGlobal();
  }

  _forwardDeleteTextAtSelection(TextSelection? sel) {
    if (sel == null) {
      return;
    }

    if (sel.isCollapsed) {
      TransactionBuilder(editorState)
        ..deleteText(node, sel.start, 1)
        ..commit();
    } else {
      TransactionBuilder(editorState)
        ..deleteText(node, sel.start, sel.extentOffset - sel.baseOffset)
        ..commit();
    }
    _setEditingStateFromGlobal();
  }

  _setEditingStateFromGlobal() {
    _textInputConnection?.setEditingState(TextEditingValue(
        text: _textContentOfDelta(node.delta),
        selection: _globalSelectionToLocal(node, editorState.cursorSelection) ??
            const TextSelection.collapsed(offset: 0)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: ((value) {
            if (value is KeyDownEvent || value is KeyRepeatEvent) {
              final sel =
                  _globalSelectionToLocal(node, editorState.cursorSelection);
              if (value.logicalKey.keyLabel == "Backspace") {
                _backDeleteTextAtSelection(sel);
              } else if (value.logicalKey.keyLabel == "Delete") {
                _forwardDeleteTextAtSelection(sel);
              }
            }
          }),
          child: SelectableText.rich(
            showCursor: true,
            TextSpan(
              children: node.toTextSpans(),
            ),
            onTap: () {
              _focusNode.requestFocus();
            },
            onSelectionChanged: ((selection, cause) {
              _textInputConnection?.close();
              _textInputConnection = TextInput.attach(
                this,
                const TextInputConfiguration(
                  enableDeltaModel: true,
                  inputType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                ),
              );
              debugPrint('selection: $selection');
              editorState.cursorSelection =
                  _localSelectionToGlobal(node, selection);
              _textInputConnection
                ?..show()
                ..setEditingState(TextEditingValue(
                    text: _textContentOfDelta(node.delta),
                    selection: selection));
            }),
          ),
        ),
        if (node.children.isNotEmpty)
          ...node.children.map(
            (e) => editorState.renderPlugins.buildWidget(
              context: NodeWidgetContext(
                buildContext: context,
                node: e,
                editorState: editorState,
              ),
            ),
          ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }

  @override
  void connectionClosed() {
    // TODO: implement connectionClosed
  }

  @override
  // TODO: implement currentAutofillScope
  AutofillScope? get currentAutofillScope => throw UnimplementedError();

  @override
  // TODO: implement currentTextEditingValue
  TextEditingValue? get currentTextEditingValue => TextEditingValue(
      text: _textContentOfDelta(node.delta),
      selection: _globalSelectionToLocal(node, editorState.cursorSelection) ??
          const TextSelection.collapsed(offset: 0));

  @override
  void insertTextPlaceholder(Size size) {
    // TODO: implement insertTextPlaceholder
  }

  @override
  void performAction(TextInputAction action) {
    debugPrint('action:$action');
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    // TODO: implement performPrivateCommand
  }

  @override
  void removeTextPlaceholder() {
    // TODO: implement removeTextPlaceholder
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    // TODO: implement showAutocorrectionPromptRect
  }

  @override
  void showToolbar() {
    // TODO: implement showToolbar
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    debugPrint('offset: ${value.selection}');
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {
    debugPrint(textEditingDeltas.toString());
    for (final textDelta in textEditingDeltas) {
      if (textDelta is TextEditingDeltaInsertion) {
        TransactionBuilder(editorState)
          ..insertText(node, textDelta.insertionOffset, textDelta.textInserted)
          ..commit();
      } else if (textDelta is TextEditingDeltaDeletion) {
        TransactionBuilder(editorState)
          ..deleteText(node, textDelta.deletedRange.start,
              textDelta.deletedRange.end - textDelta.deletedRange.start)
          ..commit();
      }
    }
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // TODO: implement updateFloatingCursor
  }
}

extension on TextNode {
  List<TextSpan> toTextSpans() => delta.operations
      .whereType<TextInsert>()
      .map((op) => _textInsertToTextSpan(op))
      .toList();

  String toRawString() => delta.operations
      .whereType<TextInsert>()
      .map((op) => op.content)
      .toString();
}

TextSpan _textInsertToTextSpan(TextInsert textInsert) {
  FontWeight? fontWeight;
  FontStyle? fontStyle;
  TextDecoration? decoration;
  GestureRecognizer? gestureRecognizer;
  Color? color;
  Color highLightColor = Colors.transparent;
  double fontSize = 16.0;
  final attributes = textInsert.attributes;
  if (attributes?['bold'] == true) {
    fontWeight = FontWeight.bold;
  }
  if (attributes?['italic'] == true) {
    fontStyle = FontStyle.italic;
  }
  if (attributes?['underline'] == true) {
    decoration = TextDecoration.underline;
  }
  if (attributes?['strikethrough'] == true) {
    decoration = TextDecoration.lineThrough;
  }
  if (attributes?['highlight'] is String) {
    highLightColor = Color(int.parse(attributes!['highlight']));
  }
  if (attributes?['href'] is String) {
    color = const Color.fromARGB(255, 55, 120, 245);
    decoration = TextDecoration.underline;
    gestureRecognizer = TapGestureRecognizer()
      ..onTap = () {
        launchUrlString(attributes?['href']);
      };
  }
  final heading = attributes?['heading'] as String?;
  if (heading != null) {
    // TODO: make it better
    if (heading == 'h1') {
      fontSize = 30.0;
    } else if (heading == 'h2') {
      fontSize = 20.0;
    }
    fontWeight = FontWeight.bold;
  }
  return TextSpan(
    text: textInsert.content,
    style: TextStyle(
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      color: color,
      fontSize: fontSize,
      backgroundColor: highLightColor,
    ),
    recognizer: gestureRecognizer,
  );
}
