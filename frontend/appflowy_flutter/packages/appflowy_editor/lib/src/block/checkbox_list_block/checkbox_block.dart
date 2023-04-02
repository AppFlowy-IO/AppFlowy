import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/block/base_component/selectable/text_selectable_state_mixin.dart';
import 'package:appflowy_editor/src/block/base_component/widget/nested_list.dart';
import 'package:appflowy_editor/src/block/text_block/text_block_with_icon.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:appflowy_editor/src/extensions/text_style_extension.dart';

class CheckboxBlock extends StatefulWidget {
  const CheckboxBlock({
    super.key,
    required this.node,
  });

  final Node node;

  @override
  State<CheckboxBlock> createState() => _CheckboxBlockState();
}

class _CheckboxBlockState extends State<CheckboxBlock>
    with TextBlockSelectableStateMixin<CheckboxBlock> {
  bool get checked => widget.node.attributes['checked'] as bool? ?? false;
  List<Node> get nodes => widget.node.children.toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final editorState = Provider.of<EditorState>(context);
    final node = widget.node;
    final delta = Delta.fromJson(List.from(node.attributes['texts']));
    final nodes = widget.node.children.toList(growable: false);

    return PaddingNestedList(
      nestedChildren:
          editorState.service.renderPluginService.buildPluginWidgets(
        context,
        nodes,
        editorState,
      ),
      child: TextBlockWithIcon(
        icon: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _setCheckStatus,
          child: FlowySvg(
            name: checked ? 'check' : 'uncheck',
            width: 20,
            height: 20,
          ),
        ),
        textBlockKey: textBlockKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        path: node.path,
        delta: delta,
        textSpanDecorator: _textSpanDecorator,
      ),
    );
  }

  Future<void> _setCheckStatus() {
    final editorState = Provider.of<EditorState>(context, listen: false);
    final tr = editorState.transaction;
    tr.updateNode(widget.node, {
      'checked': !checked,
    });
    return editorState.apply(tr);
  }

  TextSpan _textSpanDecorator(TextSpan textSpan) {
    return textSpan.updateTextStyle(TextStyle(
      decoration: checked ? TextDecoration.lineThrough : null,
      color: checked ? Colors.grey.shade400 : null,
    ));
  }
}
