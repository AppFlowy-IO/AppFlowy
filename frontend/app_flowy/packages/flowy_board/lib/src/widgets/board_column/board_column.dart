import 'package:flutter/material.dart';

import '../../rendering/board_overlay.dart';
import '../../utils/log.dart';
import '../phantom/phantom_controller.dart';
import '../flex/reorder_flex.dart';
import '../flex/drag_target_inteceptor.dart';
import 'data_controller.dart';

typedef OnColumnDragStarted = void Function(int index);
typedef OnColumnDragEnded = void Function(String listId);
typedef OnColumnReorder = void Function(
    String listId, int fromIndex, int toIndex);
typedef OnColumnDeleted = void Function(String listId, int deletedIndex);
typedef OnColumnInserted = void Function(String listId, int insertedIndex);

typedef BoardColumnCardBuilder = Widget Function(
    BuildContext context, ColumnItem item);

typedef BoardColumnHeaderBuilder = Widget Function(
    BuildContext context, BoardColumnData columnData);

typedef BoardColumnFooterBuilder = Widget Function(
    BuildContext context, BoardColumnData columnData);

class BoardColumnWidget extends StatefulWidget {
  final BoardColumnDataController dataController;
  final ScrollController? scrollController;
  final ReorderFlexConfig config;

  final OnColumnDragStarted? onDragStarted;
  final OnColumnReorder onReorder;
  final OnColumnDragEnded? onDragEnded;

  final BoardPhantomController phantomController;

  String get columnId => dataController.identifier;

  final List<String> acceptedColumns;

  final BoardColumnCardBuilder cardBuilder;

  final BoardColumnHeaderBuilder? headerBuilder;

  final BoardColumnFooterBuilder? footBuilder;

  final double? spacing;

  const BoardColumnWidget({
    Key? key,
    this.headerBuilder,
    this.footBuilder,
    required this.cardBuilder,
    required this.onReorder,
    required this.dataController,
    required this.phantomController,
    required this.acceptedColumns,
    this.config = const ReorderFlexConfig(),
    this.spacing,
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

        final header = widget.headerBuilder
            ?.call(context, widget.dataController.columnData);

        final footer =
            widget.footBuilder?.call(context, widget.dataController.columnData);

        final interceptor = CrossReorderFlexDragTargetInterceptor(
          reorderFlexId: widget.columnId,
          delegate: widget.phantomController,
          acceptedReorderFlexIds: widget.acceptedColumns,
          draggableTargetBuilder: PhantomDraggableBuilder(),
        );

        final reorderFlex = ReorderFlex(
          key: widget.key,
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
          interceptor: interceptor,
          spacing: widget.spacing,
          children: children,
        );

        return Column(
          children: [
            if (header != null) header,
            Expanded(child: reorderFlex),
            if (footer != null) footer,
          ],
        );
      },
      opaque: false,
    );
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
      return widget.cardBuilder(context, item);
    }
  }
}

void _printItems(BoardColumnDataController dataController) {
  String msg = 'Column${dataController.columnData} data: ';
  for (var element in dataController.items) {
    msg = '$msg$element,';
  }

  Log.debug(msg);
}
