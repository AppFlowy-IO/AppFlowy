import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DesktopSimpleTableWidget extends StatefulWidget {
  const DesktopSimpleTableWidget({
    super.key,
    required this.simpleTableContext,
    required this.node,
    this.enableAddColumnButton = true,
    this.enableAddRowButton = true,
    this.enableAddColumnAndRowButton = true,
    this.enableHoverEffect = true,
    this.isFeedback = false,
    this.alwaysDistributeColumnWidths = false,
  });

  /// Refer to [SimpleTableWidget.node].
  final Node node;

  /// Refer to [SimpleTableWidget.simpleTableContext].
  final SimpleTableContext simpleTableContext;

  /// Refer to [SimpleTableWidget.enableAddColumnButton].
  final bool enableAddColumnButton;

  /// Refer to [SimpleTableWidget.enableAddRowButton].
  final bool enableAddRowButton;

  /// Refer to [SimpleTableWidget.enableAddColumnAndRowButton].
  final bool enableAddColumnAndRowButton;

  /// Refer to [SimpleTableWidget.enableHoverEffect].
  final bool enableHoverEffect;

  /// Refer to [SimpleTableWidget.isFeedback].
  final bool isFeedback;

  /// Refer to [SimpleTableWidget.alwaysDistributeColumnWidths].
  final bool alwaysDistributeColumnWidths;

  @override
  State<DesktopSimpleTableWidget> createState() =>
      _DesktopSimpleTableWidgetState();
}

class _DesktopSimpleTableWidgetState extends State<DesktopSimpleTableWidget> {
  SimpleTableContext get simpleTableContext => widget.simpleTableContext;

  final scrollController = ScrollController();
  late final editorState = context.read<EditorState>();

  @override
  void initState() {
    super.initState();

    simpleTableContext.horizontalScrollController = scrollController;
  }

  @override
  void dispose() {
    simpleTableContext.horizontalScrollController = null;
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isFeedback ? _buildFeedbackTable() : _buildDesktopTable();
  }

  Widget _buildFeedbackTable() {
    return Provider.value(
      value: simpleTableContext,
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildRows(),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTable() {
    // table content
    // IntrinsicHeight is used to make the table size fit the content.
    Widget child = IntrinsicHeight(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildRows(),
      ),
    );

    if (widget.alwaysDistributeColumnWidths) {
      child = Padding(
        padding: SimpleTableConstants.tablePadding,
        child: child,
      );
    } else {
      child = Scrollbar(
        controller: scrollController,
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: SimpleTableConstants.tablePadding,
            // IntrinsicWidth is used to make the table size fit the content.
            child: IntrinsicWidth(child: child),
          ),
        ),
      );
    }

    if (widget.enableHoverEffect) {
      child = MouseRegion(
        onEnter: (event) =>
            simpleTableContext.isHoveringOnTableArea.value = true,
        onExit: (event) {
          simpleTableContext.isHoveringOnTableArea.value = false;
        },
        child: Provider.value(
          value: simpleTableContext,
          child: Stack(
            children: [
              MouseRegion(
                hitTestBehavior: HitTestBehavior.opaque,
                onEnter: (event) =>
                    simpleTableContext.isHoveringOnColumnsAndRows.value = true,
                onExit: (event) {
                  simpleTableContext.isHoveringOnColumnsAndRows.value = false;
                  simpleTableContext.hoveringTableCell.value = null;
                },
                child: child,
              ),
              if (editorState.editable) ...[
                if (widget.enableAddColumnButton)
                  SimpleTableAddColumnHoverButton(
                    editorState: editorState,
                    tableNode: widget.node,
                  ),
                if (widget.enableAddRowButton)
                  SimpleTableAddRowHoverButton(
                    editorState: editorState,
                    tableNode: widget.node,
                  ),
                if (widget.enableAddColumnAndRowButton)
                  SimpleTableAddColumnAndRowHoverButton(
                    editorState: editorState,
                    node: widget.node,
                  ),
              ],
            ],
          ),
        ),
      );
    }

    return child;
  }

  List<Widget> _buildRows() {
    final List<Widget> rows = [];

    if (SimpleTableConstants.borderType == SimpleTableBorderRenderType.table) {
      rows.add(const SimpleTableColumnDivider());
    }

    for (final child in widget.node.children) {
      rows.add(editorState.renderer.build(context, child));

      if (SimpleTableConstants.borderType ==
          SimpleTableBorderRenderType.table) {
        rows.add(const SimpleTableColumnDivider());
      }
    }

    return rows;
  }
}
