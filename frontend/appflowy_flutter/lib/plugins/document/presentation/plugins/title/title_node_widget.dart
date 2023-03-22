import '../../../application/doc_bloc.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

const String kTitleType = 'title';
const String kTitleAttribute = 'docBloc';

class TitleNodeWidgetBuilder extends NodeWidgetBuilder {
  TitleNodeWidgetBuilder({required this.docBloc});
  final DocumentBloc docBloc;
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _TitleNodeWidget(
        key: context.node.key,
        node: context.node,
        editorState: context.editorState,
        title: docBloc);
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return true;
      };
}

class _TitleNodeWidget extends StatefulWidget {
  const _TitleNodeWidget(
      {Key? key,
      required this.node,
      required this.editorState,
      required this.title})
      : super(key: key);

  final Node node;
  final EditorState editorState;
  final DocumentBloc? title;

  @override
  State<_TitleNodeWidget> createState() => _TitleNodeWidgetState();
}

class _TitleNodeWidgetState extends State<_TitleNodeWidget> {
  _TitleNodeWidgetState();
  late DocumentBloc? docBloc;
  final focusNode = FocusNode();
  var textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController.fromValue(
        TextEditingValue(text: docBloc!.view.name.toString()));
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        child: EditableText(
      controller: textEditingController,
      autofocus: true,
      focusNode: focusNode,
      style: const TextStyle(
          color: Colors.black, fontSize: 50.0, fontWeight: FontWeight.bold),
      cursorColor: Colors.blue,
      backgroundCursorColor: Colors.blue,
      onSubmitted: (value) {
        setState(() {
          //NOTE: The property is only READONLY
          // docBloc!.view.name = value;
        });
      },
    ));
  }
}
