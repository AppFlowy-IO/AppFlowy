import 'dart:collection';

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
  String listId,
  int fromIndex,
  int toIndex,
);

typedef OnColumnDeleted = void Function(String listId, int deletedIndex);

typedef OnColumnInserted = void Function(String listId, int insertedIndex);

typedef BoardColumnCardBuilder = Widget Function(
  BuildContext context,
  ColumnItem item,
);

typedef BoardColumnHeaderBuilder = Widget Function(
  BuildContext context,
  BoardColumnData columnData,
);

typedef BoardColumnFooterBuilder = Widget Function(
  BuildContext context,
  BoardColumnData columnData,
);

abstract class BoardColumnDataDataSource extends ReoderFlextDataSource {
  BoardColumnData get columnData;

  List<String> get acceptedColumnIds;

  @override
  String get identifier => columnData.id;

  @override
  UnmodifiableListView<ColumnItem> get items => columnData.items;

  void debugPrint() {
    String msg = '[$BoardColumnDataDataSource] $columnData data: ';
    for (var element in items) {
      msg = '$msg$element,';
    }

    Log.debug(msg);
  }
}

/// [BoardColumnWidget] represents the column of the Board.
///
class BoardColumnWidget extends StatefulWidget {
  final BoardColumnDataDataSource dataSource;
  final ScrollController? scrollController;
  final ReorderFlexConfig config;

  final OnColumnDragStarted? onDragStarted;
  final OnColumnReorder onReorder;
  final OnColumnDragEnded? onDragEnded;

  final BoardPhantomController phantomController;

  String get columnId => dataSource.columnData.id;

  final BoardColumnCardBuilder cardBuilder;

  final BoardColumnHeaderBuilder? headerBuilder;

  final BoardColumnFooterBuilder? footBuilder;

  BoardColumnWidget({
    Key? key,
    this.headerBuilder,
    this.footBuilder,
    required this.cardBuilder,
    required this.onReorder,
    required this.dataSource,
    required this.phantomController,
    this.onDragStarted,
    this.scrollController,
    this.onDragEnded,
    double? spacing,
  })  : config = ReorderFlexConfig(spacing: spacing),
        super(key: key);

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
        final children = widget.dataSource.columnData.items
            .map((item) => _buildWidget(context, item))
            .toList();

        final header =
            widget.headerBuilder?.call(context, widget.dataSource.columnData);

        final footer =
            widget.footBuilder?.call(context, widget.dataSource.columnData);

        final interceptor = CrossReorderFlexDragTargetInterceptor(
          reorderFlexId: widget.columnId,
          delegate: widget.phantomController,
          acceptedReorderFlexIds: widget.dataSource.acceptedColumnIds,
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
            widget.dataSource.debugPrint();
          },
          dataSource: widget.dataSource,
          interceptor: interceptor,
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
