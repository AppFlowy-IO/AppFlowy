import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../application/doc_bloc.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

const String kTitleType = 'title';

class TitleNodeWidgetBuilder extends NodeWidgetBuilder {
  TitleNodeWidgetBuilder({required this.docBloc});
  final DocumentBloc docBloc;
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _TitleNodeWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) => true;
}

class _TitleNodeWidget extends StatefulWidget {
  const _TitleNodeWidget({
    super.key,
    required this.node,
    required this.editorState,
  });

  final Node node;
  final EditorState editorState;

  @override
  State<_TitleNodeWidget> createState() => _TitleNodeWidgetState();
}

class _TitleNodeWidgetState extends State<_TitleNodeWidget> {
  _TitleNodeWidgetState();
  late final DocumentBloc docBloc = context.read<DocumentBloc>();
  final focusNode = FocusNode();
  var textEditingController = TextEditingController();
  final service = ViewService();

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController.fromValue(
      TextEditingValue(
        text: docBloc.view.name.toString(),
      ),
    );
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  void _updateName(String value) async {
    await service.updateView(viewId: docBloc.view.id, name: value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      child: EditableText(
        controller: textEditingController,
        autofocus: true,
        focusNode: focusNode,
        selectionColor: theme.highlightColor,
        style: AFThemeExtension.of(context).pageTitle,
        cursorColor: theme.highlightColor,
        backgroundCursorColor: theme.highlightColor,
        onSubmitted: (value) {
          _updateName;
        },
      ),
      onExit: (e) {
        _updateName(textEditingController.text);
        focusNode.unfocus();
      },
      onHover: (e) {
        focusNode.requestFocus();
      },
    );
  }
}
