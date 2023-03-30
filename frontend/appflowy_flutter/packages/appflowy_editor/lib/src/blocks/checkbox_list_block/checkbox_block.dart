import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/base_component/widget/nested_list.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CheckboxBlock extends StatefulWidget {
  const CheckboxBlock({
    super.key,
    required this.node,
  });

  final Node node;

  @override
  State<CheckboxBlock> createState() => _CheckboxBlockState();
}

class _CheckboxBlockState extends State<CheckboxBlock> {
  bool get check => widget.node.attributes['check'] as bool? ?? false;
  List<Node> get nodes => widget.node.children.toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final editorState = Provider.of<EditorState>(context);
    return NestedList(
      nestedChildren:
          editorState.service.renderPluginService.buildPluginWidgets(
        context,
        nodes,
        editorState,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _setCheckStatus,
        child: FlowySvg(
          name: check ? 'check' : 'uncheck',
          width: 20,
          height: 20,
        ),
      ),
    );
  }

  Future<void> _setCheckStatus() {
    final editorState = Provider.of<EditorState>(context, listen: false);
    final tr = editorState.transaction;
    tr.updateNode(widget.node, {
      'check': !check,
    });
    return editorState.apply(tr);
  }
}
