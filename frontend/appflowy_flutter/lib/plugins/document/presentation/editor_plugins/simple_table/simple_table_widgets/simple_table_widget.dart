import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

class SimpleTableWidget extends StatefulWidget {
  const SimpleTableWidget({
    super.key,
    required this.simpleTableContext,
    required this.node,
    this.enableAddColumnButton = true,
    this.enableAddRowButton = true,
    this.enableAddColumnAndRowButton = true,
    this.enableHoverEffect = true,
    this.isFeedback = false,
  });

  /// The node of the table.
  ///
  /// Its type must be [SimpleTableBlockKeys.type].
  final Node node;

  /// The context of the simple table.
  final SimpleTableContext simpleTableContext;

  /// Whether to show the add column button.
  ///
  /// For the feedback widget builder, it should be false.
  final bool enableAddColumnButton;

  /// Whether to show the add row button.
  ///
  /// For the feedback widget builder, it should be false.
  final bool enableAddRowButton;

  /// Whether to show the add column and row button.
  ///
  /// For the feedback widget builder, it should be false.
  final bool enableAddColumnAndRowButton;

  /// Whether to enable the hover effect.
  ///
  /// For the feedback widget builder, it should be false.
  final bool enableHoverEffect;

  /// Whether the widget is a feedback widget.
  final bool isFeedback;

  @override
  State<SimpleTableWidget> createState() => _SimpleTableWidgetState();
}

class _SimpleTableWidgetState extends State<SimpleTableWidget> {
  SimpleTableContext get simpleTableContext => widget.simpleTableContext;

  final scrollController = ScrollController();
  late final editorState = context.read<EditorState>();

  @override
  void dispose() {
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UniversalPlatform.isDesktop
        ? _buildDesktopTable()
        : _buildMobileTable();
  }

  Widget _buildDesktopTable() {
    if (widget.isFeedback) {
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

    // table content
    Widget child = Scrollbar(
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: SimpleTableConstants.tablePadding,
          // IntrinsicWidth and IntrinsicHeight are used to make the table size fit the content.
          child: IntrinsicWidth(
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildRows(),
              ),
            ),
          ),
        ),
      ),
    );

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

  Widget _buildMobileTable() {
    return Provider.value(
      value: simpleTableContext,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth(
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildRows(),
            ),
          ),
        ),
      ),
    );
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
