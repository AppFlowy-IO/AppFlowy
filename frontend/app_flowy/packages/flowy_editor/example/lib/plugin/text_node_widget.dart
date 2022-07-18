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

class __TextNodeWidgetState extends State<_TextNodeWidget>
    implements TextInputClient {
  TextNode get node => widget.node as TextNode;
  EditorState get editorState => widget.editorState;
  TextEditingValue get textEditingValue => TextEditingValue(
        text: node.toRawString(),
      );

  TextInputConnection? _textInputConnection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText.rich(
          TextSpan(
            children: node.toTextSpans(),
          ),
          onTap: () {
            _textInputConnection?.close();
            _textInputConnection = TextInput.attach(
              this,
              const TextInputConfiguration(
                enableDeltaModel: false,
                inputType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
            );
            _textInputConnection
              ?..show()
              ..setEditingState(textEditingValue);
          },
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
  TextEditingValue? get currentTextEditingValue => textEditingValue;

  @override
  void insertTextPlaceholder(Size size) {
    // TODO: implement insertTextPlaceholder
  }

  @override
  void performAction(TextInputAction action) {
    // TODO: implement performAction
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
    debugPrint(value.text);
    editorState.update(node, {'content': value.text});
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
  if (attributes?['href'] is String) {
    color = const Color.fromARGB(255, 55, 120, 245);
    decoration = TextDecoration.underline;
    gestureRecognizer = TapGestureRecognizer()
      ..onTap = () {
        launchUrlString(attributes?['href']);
      };
  }
  return TextSpan(
    text: textInsert.content,
    style: TextStyle(
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      color: color,
      fontSize: 16,
    ),
    recognizer: gestureRecognizer,
  );
}
