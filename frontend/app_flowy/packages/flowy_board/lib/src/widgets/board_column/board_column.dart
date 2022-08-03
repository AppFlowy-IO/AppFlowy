import 'package:flutter/material.dart';

import '../../rendering/board_overlay.dart';
import '../../utils/log.dart';
import '../phantom/phantom_controller.dart';
import '../flex/reorder_flex.dart';
import '../flex/drag_state.dart';
import '../flex/reorder_flex_ext.dart';
import 'data_controller.dart';

typedef OnDragStarted = void Function(int index);
typedef OnDragEnded = void Function(String listId);
typedef OnReorder = void Function(String listId, int fromIndex, int toIndex);
typedef OnDeleted = void Function(String listId, int deletedIndex);
typedef OnInserted = void Function(String listId, int insertedIndex);
typedef OnPassedInPhantom = void Function(
  String listId,
  FlexDragTargetData dragTargetData,
  int phantomIndex,
);

typedef BoardColumnItemWidgetBuilder = Widget Function(
    BuildContext context, ColumnItem item);

class BoardColumnWidget extends StatefulWidget {
  final Widget? header;
  final Widget? footer;
  final BoardColumnDataController dataController;
  final ScrollController? scrollController;
  final ReorderFlexConfig config;

  final OnDragStarted? onDragStarted;
  final OnReorder onReorder;
  final OnDragEnded? onDragEnded;

  final BoardPhantomController phantomController;

  String get columnId => dataController.identifier;

  final List<String> acceptColumns;

  final BoardColumnItemWidgetBuilder builder;

  const BoardColumnWidget({
    Key? key,
    this.header,
    this.footer,
    required this.builder,
    required this.onReorder,
    required this.dataController,
    required this.phantomController,
    required this.acceptColumns,
    this.config = const ReorderFlexConfig(),
    this.onDragStarted,
    this.scrollController,
    this.onDragEnded,
  }) : super(key: key);

  @override
  State<BoardColumnWidget> createState() => _BoardColumnWidgetState();
}

class _BoardColumnWidgetState extends State<BoardColumnWidget> {
  final GlobalKey _columnOverlayKey =
      GlobalKey(debugLabel: '$BoardColumnWidget overlay key');

  late BoardOverlayEntry _overlayEntry;

  @override
  void initState() {
    _overlayEntry = BoardOverlayEntry(
        builder: (BuildContext context) {
          final children = widget.dataController.items
              .map((item) => _buildWidget(context, item))
              .toList();

          final dragTargetExtension = ReorderFlextDragTargetExtension(
            reorderFlexId: widget.columnId,
            delegate: widget.phantomController,
            acceptReorderFlexIds: widget.acceptColumns,
            draggableTargetBuilder: PhantomReorderDraggableBuilder(),
          );

          return ReorderFlex(
            key: widget.key,
            header: widget.header,
            footer: widget.footer,
            scrollController: widget.scrollController,
            config: widget.config,
            onDragStarted: (index) {
              widget.phantomController.columnStartDragging(widget.columnId);
              widget.onDragStarted?.call(index);
            },
            onReorder: ((fromIndex, toIndex) {
              if (widget.phantomController.isFromColumn(widget.columnId)) {
                widget.onReorder(widget.columnId, fromIndex, toIndex);
                widget.phantomController.transformIndex(fromIndex, toIndex);
              }
            }),
            onDragEnded: () {
              widget.phantomController.columnEndDragging(widget.columnId);
              widget.onDragEnded?.call(widget.columnId);
              _printItems(widget.dataController);
            },
            dataSource: widget.dataController,
            dragTargetExtension: dragTargetExtension,
            children: children,
          );
        },
        opaque: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BoardOverlay(
      key: _columnOverlayKey,
      initialEntries: [_overlayEntry],
    );
  }

  Widget _buildWidget(BuildContext context, ColumnItem item) {
    if (item is PhantomColumnItem) {
      return PassthroughPhantomWidget(
        key: UniqueKey(),
        opacity: widget.config.draggingWidgetOpacity,
        passthroughPhantomContext: item.phantomContext,
      );
    } else {
      return widget.builder(context, item);
    }
  }
}

void _printItems(BoardColumnDataController dataController) {
  String msg = '';
  for (var element in dataController.items) {
    msg = '$msg$element,';
  }

  Log.debug(msg);
}
