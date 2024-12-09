import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimpleTableAddColumnHoverButton extends StatefulWidget {
  const SimpleTableAddColumnHoverButton({
    super.key,
    required this.editorState,
    required this.node,
  });

  final EditorState editorState;
  final Node node;

  @override
  State<SimpleTableAddColumnHoverButton> createState() =>
      _SimpleTableAddColumnHoverButtonState();
}

class _SimpleTableAddColumnHoverButtonState
    extends State<SimpleTableAddColumnHoverButton> {
  late final interceptorKey =
      'simple_table_add_column_hover_button_${widget.node.id}';

  SelectionGestureInterceptor? interceptor;

  @override
  void initState() {
    super.initState();

    interceptor = SelectionGestureInterceptor(
      key: interceptorKey,
      canTap: (details) => !_isTapInBounds(details.globalPosition),
    );
    widget.editorState.service.selectionService
        .registerGestureInterceptor(interceptor!);
  }

  @override
  void dispose() {
    widget.editorState.service.selectionService.unregisterGestureInterceptor(
      interceptorKey,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.node.type == SimpleTableBlockKeys.type);

    if (widget.node.type != SimpleTableBlockKeys.type) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder(
      valueListenable: context.read<SimpleTableContext>().isHoveringOnTableArea,
      builder: (context, isHoveringOnTableArea, _) {
        return ValueListenableBuilder(
          valueListenable: context.read<SimpleTableContext>().hoveringTableCell,
          builder: (context, hoveringTableCell, _) {
            bool shouldShow = isHoveringOnTableArea;
            if (hoveringTableCell != null &&
                SimpleTableConstants.enableHoveringLogicV2) {
              shouldShow = hoveringTableCell.columnIndex + 1 ==
                  hoveringTableCell.columnLength;
            }
            return Positioned(
              top: SimpleTableConstants.tableTopPadding -
                  SimpleTableConstants.cellBorderWidth,
              bottom: SimpleTableConstants.addColumnButtonBottomPadding,
              right: 0,
              child: Opacity(
                opacity: shouldShow ? 1.0 : 0.0,
                child: SimpleTableAddColumnButton(
                  onTap: () {
                    widget.editorState.addColumnInTable(widget.node);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isTapInBounds(Offset offset) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return false;
    }

    final localPosition = renderBox.globalToLocal(offset);
    final result = renderBox.paintBounds.contains(localPosition);

    return result;
  }
}

class SimpleTableAddColumnButton extends StatelessWidget {
  const SimpleTableAddColumnButton({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.document_plugins_simpleTable_clickToAddNewColumn.tr(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: SimpleTableConstants.addColumnButtonWidth,
            margin: const EdgeInsets.symmetric(
              horizontal: SimpleTableConstants.addColumnButtonPadding,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                SimpleTableConstants.addColumnButtonRadius,
              ),
              color: context.simpleTableMoreActionBackgroundColor,
            ),
            child: const FlowySvg(
              FlowySvgs.add_s,
            ),
          ),
        ),
      ),
    );
  }
}
