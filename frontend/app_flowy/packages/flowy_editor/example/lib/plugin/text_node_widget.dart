import 'package:flutter/material.dart';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class TextNodeBuilder extends NodeWidgetBuilder {
  TextNodeBuilder.create({
    required super.node,
    required super.editorState,
  }) : super.create();

  String get content => node.attributes['content'] as String;

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
  Node get node => widget.node;
  EditorState get editorState => widget.editorState;
  String get content => node.attributes['content'] as String;
  TextEditingValue get textEditingValue => TextEditingValue(text: content);

  TextInputConnection? _textInputConnection;

  @override
  Widget build(BuildContext context) {
    final editableRichText = ChangeNotifierProvider.value(
      value: node,
      builder: (_, __) => Consumer<Node>(
        builder: ((context, value, child) => SelectableText.rich(
              TextSpan(
                text: content,
                style: node.attributes.toTextStyle(),
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
            )),
      ),
    );

    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        editableRichText,
        if (node.children.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: node.children
                .map(
                  (e) => editorState.renderPlugins.buildWidget(
                    context: NodeWidgetContext(
                      buildContext: context,
                      node: e,
                      editorState: editorState,
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
    return child;
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
    editorState.update(
      node,
      Attributes.from(node.attributes)
        ..addAll(
          {
            'content': value.text,
          },
        ),
    );
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // TODO: implement updateFloatingCursor
  }
}
