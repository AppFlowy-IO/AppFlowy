import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

final alignToolbarItem = ToolbarItem(
  id: 'editor.align',
  group: 4,
  isActive: onlyShowInTextType,
  builder: (context, editorState, highlightColor) {
    final selection = editorState.selection!;
    final nodes = editorState.getNodesInSelection(selection);

    bool isSatisfyCondition(bool Function(Object? value) test) {
      return nodes.every(
        (n) => test(n.attributes[blockComponentAlign]),
      );
    }

    bool isHighlight = false;
    FlowySvgData data = FlowySvgs.toolbar_align_left_s;
    if (isSatisfyCondition((value) => value == 'left')) {
      isHighlight = true;
      data = FlowySvgs.toolbar_align_left_s;
    } else if (isSatisfyCondition((value) => value == 'center')) {
      isHighlight = true;
      data = FlowySvgs.toolbar_align_center_s;
    } else if (isSatisfyCondition((value) => value == 'right')) {
      isHighlight = true;
      data = FlowySvgs.toolbar_align_right_s;
    }

    final child = FlowySvg(
      data,
      size: const Size.square(16),
      color: isHighlight ? highlightColor : Colors.white,
    );
    return _AlignmentButtons(
      child: child,
      onAlignChanged: (align) async {
        await editorState.updateNode(
          selection,
          (node) => node.copyWith(
            attributes: {
              ...node.attributes,
              blockComponentAlign: align,
            },
          ),
        );
      },
    );
  },
);

class _AlignmentButtons extends StatefulWidget {
  const _AlignmentButtons({
    required this.child,
    required this.onAlignChanged,
  });

  final Widget child;
  final Function(String align) onAlignChanged;

  @override
  State<_AlignmentButtons> createState() => _AlignmentButtonsState();
}

class _AlignmentButtonsState extends State<_AlignmentButtons> {
  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      windowPadding: const EdgeInsets.all(0),
      margin: const EdgeInsets.all(0),
      direction: PopoverDirection.bottomWithCenterAligned,
      offset: const Offset(0, 10),
      child: widget.child,
      popupBuilder: (_) => _AlignButtons(onAlignChanged: widget.onAlignChanged),
    );
  }
}

class _AlignButtons extends StatelessWidget {
  const _AlignButtons({
    required this.onAlignChanged,
  });

  final Function(String align) onAlignChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HSpace(4),
          _AlignButton(
            icon: FlowySvgs.toolbar_align_left_s,
            onTap: () => onAlignChanged('left'),
          ),
          const _Divider(),
          _AlignButton(
            icon: FlowySvgs.toolbar_align_center_s,
            onTap: () => onAlignChanged('center'),
          ),
          const _Divider(),
          _AlignButton(
            icon: FlowySvgs.toolbar_align_right_s,
            onTap: () => onAlignChanged('right'),
          ),
          const HSpace(4),
        ],
      ),
    );
  }
}

class _AlignButton extends StatelessWidget {
  const _AlignButton({
    required this.icon,
    required this.onTap,
  });

  final FlowySvgData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FlowySvg(
        icon,
        size: const Size.square(16),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        width: 1,
        color: Colors.grey,
      ),
    );
  }
}
