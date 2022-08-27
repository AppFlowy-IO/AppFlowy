import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'board_column/board_column.dart';
import 'board_column/board_column_data.dart';
import 'board_data.dart';
import 'reorder_flex/drag_target_interceptor.dart';
import 'reorder_flex/reorder_flex.dart';
import 'reorder_phantom/phantom_controller.dart';
import '../rendering/board_overlay.dart';

class AFBoardScrollManager {
  BoardColumnState? _columnState;

  // AFBoardScrollManager();

  void scrollToBottom(String columnId, VoidCallback? completed) {
    _columnState?.reorderFlexStateAtColumn(columnId)?.scrollToBottom(completed);
  }
}

class AFBoardConfig {
  final double cornerRadius;
  final EdgeInsets columnPadding;
  final EdgeInsets columnItemPadding;
  final EdgeInsets footerPadding;
  final EdgeInsets headerPadding;
  final EdgeInsets cardPadding;
  final Color columnBackgroundColor;

  const AFBoardConfig({
    this.cornerRadius = 6.0,
    this.columnPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.columnItemPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.footerPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.cardPadding = const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
    this.columnBackgroundColor = Colors.transparent,
  });
}

class AFBoard extends StatelessWidget {
  /// The direction to use as the main axis.
  final Axis direction = Axis.vertical;

  ///
  final Widget? background;

  ///
  final AFBoardColumnCardBuilder cardBuilder;

  ///
  final AFBoardColumnHeaderBuilder? headerBuilder;

  ///
  final AFBoardColumnFooterBuilder? footBuilder;

  ///
  final AFBoardDataController dataController;

  final BoxConstraints columnConstraints;

  ///
  final BoardPhantomController phantomController;

  final ScrollController? scrollController;

  final AFBoardConfig config;

  final AFBoardScrollManager? scrollManager;

  final BoardColumnState _columnState = BoardColumnState();

  AFBoard({
    required this.dataController,
    required this.cardBuilder,
    this.background,
    this.footBuilder,
    this.headerBuilder,
    this.scrollController,
    this.scrollManager,
    this.columnConstraints = const BoxConstraints(maxWidth: 200),
    this.config = const AFBoardConfig(),
    Key? key,
  })  : phantomController = BoardPhantomController(delegate: dataController),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: dataController,
      child: Consumer<AFBoardDataController>(
        builder: (context, notifier, child) {
          if (scrollManager != null) {
            scrollManager!._columnState = _columnState;
          }

          return AFBoardContent(
            config: config,
            dataController: dataController,
            scrollController: scrollController,
            scrollManager: scrollManager,
            columnState: _columnState,
            background: background,
            delegate: phantomController,
            columnConstraints: columnConstraints,
            cardBuilder: cardBuilder,
            footBuilder: footBuilder,
            headerBuilder: headerBuilder,
            phantomController: phantomController,
            onReorder: dataController.moveColumn,
          );
        },
      ),
    );
  }
}

class AFBoardContent extends StatefulWidget {
  final ScrollController? scrollController;
  final OnDragStarted? onDragStarted;
  final OnReorder onReorder;
  final OnDragEnded? onDragEnded;
  final AFBoardDataController dataController;
  final Widget? background;
  final AFBoardConfig config;
  final ReorderFlexConfig reorderFlexConfig;
  final BoxConstraints columnConstraints;
  final AFBoardScrollManager? scrollManager;
  final BoardColumnState columnState;

  ///
  final AFBoardColumnCardBuilder cardBuilder;

  ///
  final AFBoardColumnHeaderBuilder? headerBuilder;

  ///
  final AFBoardColumnFooterBuilder? footBuilder;

  final OverlapDragTargetDelegate delegate;

  final BoardPhantomController phantomController;

  const AFBoardContent({
    required this.config,
    required this.onReorder,
    required this.delegate,
    required this.dataController,
    required this.scrollManager,
    required this.columnState,
    this.onDragStarted,
    this.onDragEnded,
    this.scrollController,
    this.background,
    required this.columnConstraints,
    required this.cardBuilder,
    this.footBuilder,
    this.headerBuilder,
    required this.phantomController,
    Key? key,
  })  : reorderFlexConfig = const ReorderFlexConfig(),
        super(key: key);

  @override
  State<AFBoardContent> createState() => _AFBoardContentState();
}

class _AFBoardContentState extends State<AFBoardContent> {
  final GlobalKey _boardContentKey =
      GlobalKey(debugLabel: '$AFBoardContent overlay key');
  late BoardOverlayEntry _overlayEntry;

  @override
  void initState() {
    _overlayEntry = BoardOverlayEntry(
      builder: (BuildContext context) {
        final interceptor = OverlappingDragTargetInterceptor(
          reorderFlexId: widget.dataController.identifier,
          acceptedReorderFlexId: widget.dataController.columnIds,
          delegate: widget.delegate,
          columnKeys: UnmodifiableMapView(widget.columnState.columnKeys),
        );

        final reorderFlex = ReorderFlex(
          key: widget.key,
          config: widget.reorderFlexConfig,
          scrollController: widget.scrollController,
          onDragStarted: widget.onDragStarted,
          onReorder: widget.onReorder,
          onDragEnded: widget.onDragEnded,
          dataSource: widget.dataController,
          direction: Axis.horizontal,
          interceptor: interceptor,
          children: _buildColumns(),
        );

        return Stack(
          alignment: AlignmentDirectional.topStart,
          children: [
            if (widget.background != null)
              Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(widget.config.cornerRadius),
                ),
                child: widget.background,
              ),
            reorderFlex,
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
      key: _boardContentKey,
      initialEntries: [_overlayEntry],
    );
  }

  List<Widget> _buildColumns() {
    final List<Widget> children =
        widget.dataController.columnDatas.asMap().entries.map(
      (item) {
        final columnData = item.value;
        final columnIndex = item.key;

        final dataSource = _BoardColumnDataSourceImpl(
          columnId: columnData.id,
          dataController: widget.dataController,
        );

        return ChangeNotifierProvider.value(
          key: ValueKey(columnData.id),
          value: widget.dataController.getColumnController(columnData.id),
          child: Consumer<AFBoardColumnDataController>(
            builder: (context, value, child) {
              final scrollController =
                  widget.columnState.scrollController(columnData.id);
              final boardColumn = AFBoardColumnWidget(
                key: ValueKey(columnData.id),
                margin: _marginFromIndex(columnIndex),
                itemMargin: widget.config.columnItemPadding,
                headerBuilder: _buildHeader,
                footBuilder: widget.footBuilder,
                cardBuilder: widget.cardBuilder,
                dataSource: dataSource,
                scrollController: scrollController,
                phantomController: widget.phantomController,
                onReorder: widget.dataController.moveColumnItem,
                cornerRadius: widget.config.cornerRadius,
                backgroundColor: widget.config.columnBackgroundColor,
              );

              widget.columnState.addColumn(
                columnData.id,
                boardColumn.globalKey,
              );

              return ConstrainedBox(
                constraints: widget.columnConstraints,
                child: boardColumn,
              );
            },
          ),
        );
      },
    ).toList();

    return children;
  }

  Widget? _buildHeader(
      BuildContext context, AFBoardColumnHeaderData headerData) {
    if (widget.headerBuilder == null) {
      return null;
    }
    return Selector<AFBoardColumnDataController, AFBoardColumnHeaderData>(
      selector: (context, controller) => controller.columnData.headerData,
      builder: (context, headerData, _) {
        return widget.headerBuilder!(context, headerData)!;
      },
    );
  }

  EdgeInsets _marginFromIndex(int index) {
    if (widget.dataController.columnDatas.isEmpty) {
      return widget.config.columnPadding;
    }

    if (index == 0) {
      return EdgeInsets.only(right: widget.config.columnPadding.right);
    }

    if (index == widget.dataController.columnDatas.length - 1) {
      return EdgeInsets.only(left: widget.config.columnPadding.left);
    }

    return widget.config.columnPadding;
  }
}

class _BoardColumnDataSourceImpl extends AFBoardColumnDataDataSource {
  String columnId;
  final AFBoardDataController dataController;

  _BoardColumnDataSourceImpl({
    required this.columnId,
    required this.dataController,
  });

  @override
  AFBoardColumnData get columnData =>
      dataController.getColumnController(columnId)!.columnData;

  @override
  List<String> get acceptedColumnIds => dataController.columnIds;
}

class BoardColumnState {
  /// Quick access to the [AFBoardColumnWidget]
  final Map<String, GlobalKey> columnKeys = {};

  /// Records the position of the [AFBoardColumnWidget]
  final Map<String, ScrollPosition> columnScrollPositions = {};

  void addColumn(String columnId, GlobalKey key) {
    columnKeys[columnId] = key;
  }

  ReorderFlexState? reorderFlexStateAtColumn(String columnId) {
    final flexGlobalKey = columnKeys[columnId];
    if (flexGlobalKey == null) return null;
    if (flexGlobalKey.currentState is! ReorderFlexState) return null;
    final state = flexGlobalKey.currentState as ReorderFlexState;
    return state;
  }

  ReorderFlex? reorderFlexAtColumn(String columnId) {
    final flexGlobalKey = columnKeys[columnId];
    if (flexGlobalKey == null) return null;
    if (flexGlobalKey.currentWidget is! ReorderFlex) return null;
    final widget = flexGlobalKey.currentWidget as ReorderFlex;
    return widget;
  }

  ScrollController scrollController(String columnId) {
    ScrollController scrollController = ScrollController();

    return scrollController;
  }
}
