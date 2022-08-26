import 'dart:collection';

import 'package:flutter/material.dart';
import '../../rendering/board_overlay.dart';
import '../../utils/log.dart';
import '../reorder_phantom/phantom_controller.dart';
import '../reorder_flex/reorder_flex.dart';
import '../reorder_flex/drag_target_interceptor.dart';
import 'board_column_data.dart';

typedef OnColumnDragStarted = void Function(int index);

typedef OnColumnDragEnded = void Function(String listId);

typedef OnColumnReorder = void Function(
  String listId,
  int fromIndex,
  int toIndex,
);

typedef OnColumnDeleted = void Function(String listId, int deletedIndex);

typedef OnColumnInserted = void Function(String listId, int insertedIndex);

typedef AFBoardColumnCardBuilder = Widget Function(
  BuildContext context,
  AFBoardColumnData columnData,
  AFColumnItem item,
);

typedef AFBoardColumnHeaderBuilder = Widget? Function(
  BuildContext context,
  AFBoardColumnHeaderData headerData,
);

typedef AFBoardColumnFooterBuilder = Widget Function(
  BuildContext context,
  AFBoardColumnData columnData,
);

abstract class AFBoardColumnDataDataSource extends ReoderFlexDataSource {
  AFBoardColumnData get columnData;

  List<String> get acceptedColumnIds;

  @override
  String get identifier => columnData.id;

  @override
  UnmodifiableListView<AFColumnItem> get items => columnData.items;

  void debugPrint() {
    String msg = '[$AFBoardColumnDataDataSource] $columnData data: ';
    for (var element in items) {
      msg = '$msg$element,';
    }

    Log.debug(msg);
  }
}

/// [AFBoardColumnWidget] represents the column of the Board.
///
class AFBoardColumnWidget extends StatefulWidget {
  final AFBoardColumnDataDataSource dataSource;
  final ScrollController? scrollController;
  final ReorderFlexConfig config;

  final OnColumnDragStarted? onDragStarted;
  final OnColumnReorder onReorder;
  final OnColumnDragEnded? onDragEnded;

  final BoardPhantomController phantomController;

  String get columnId => dataSource.columnData.id;

  final AFBoardColumnCardBuilder cardBuilder;

  final AFBoardColumnHeaderBuilder? headerBuilder;

  final AFBoardColumnFooterBuilder? footBuilder;

  final EdgeInsets margin;

  final EdgeInsets itemMargin;

  final double cornerRadius;

  final Color backgroundColor;

  final GlobalKey globalKey = GlobalKey();

  AFBoardColumnWidget({
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
    this.margin = EdgeInsets.zero,
    this.itemMargin = EdgeInsets.zero,
    this.cornerRadius = 0.0,
    this.backgroundColor = Colors.transparent,
  })  : config = const ReorderFlexConfig(),
        super(key: key);

  @override
  State<AFBoardColumnWidget> createState() => _AFBoardColumnWidgetState();
}

class _AFBoardColumnWidgetState extends State<AFBoardColumnWidget> {
  final GlobalKey _columnOverlayKey =
      GlobalKey(debugLabel: '$AFBoardColumnWidget overlay key');

  late GlobalObjectKey _indexGlobalKey;

  late BoardOverlayEntry _overlayEntry;

  @override
  void initState() {
    _indexGlobalKey = GlobalObjectKey(widget.key!);
    _overlayEntry = BoardOverlayEntry(
      builder: (BuildContext context) {
        final children = widget.dataSource.columnData.items
            .map((item) => _buildWidget(context, item))
            .toList();

        final header = widget.headerBuilder
            ?.call(context, widget.dataSource.columnData.headerData);

        final footer =
            widget.footBuilder?.call(context, widget.dataSource.columnData);

        final interceptor = CrossReorderFlexDragTargetInterceptor(
          reorderFlexId: widget.columnId,
          delegate: widget.phantomController,
          acceptedReorderFlexIds: widget.dataSource.acceptedColumnIds,
          draggableTargetBuilder: PhantomDraggableBuilder(),
        );

        Widget reorderFlex = ReorderFlex(
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

        reorderFlex = KeyedSubtree(key: _indexGlobalKey, child: reorderFlex);

        return Container(
          margin: widget.margin,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.cornerRadius),
          ),
          child: Column(
            children: [
              if (header != null) header,
              Expanded(
                child: Padding(padding: widget.itemMargin, child: reorderFlex),
              ),
              if (footer != null) footer,
            ],
          ),
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

  Widget _buildWidget(BuildContext context, AFColumnItem item) {
    if (item is PhantomColumnItem) {
      return PassthroughPhantomWidget(
        key: UniqueKey(),
        opacity: widget.config.draggingWidgetOpacity,
        passthroughPhantomContext: item.phantomContext,
      );
    } else {
      return widget.cardBuilder(context, widget.dataSource.columnData, item);
    }
  }
}
