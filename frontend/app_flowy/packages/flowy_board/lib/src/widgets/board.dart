import 'dart:collection';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../flowy_board.dart';

import '../rendering/board_overlay.dart';
import 'flex/drag_target_inteceptor.dart';
import 'flex/reorder_flex.dart';
import 'phantom/phantom_controller.dart';

class Board extends StatelessWidget {
  /// The direction to use as the main axis.
  final Axis direction = Axis.vertical;

  /// How much space to place between children in a run in the main axis.
  /// Defaults to 10.0.
  final double spacing;

  /// How much space to place between the runs themselves in the cross axis.
  /// Defaults to 0.0.
  final double runSpacing;

  ///
  final Widget? background;

  ///
  final BoardColumnCardBuilder cardBuilder;

  ///
  final BoardColumnHeaderBuilder? headerBuilder;

  ///
  final BoardColumnFooterBuilder? footBuilder;

  ///
  final BoardDataController dataController;

  final BoxConstraints columnConstraints;

  ///
  final BoardPhantomController phantomController;

  Board({
    required this.dataController,
    required this.cardBuilder,
    this.spacing = 10.0,
    this.runSpacing = 0.0,
    this.background,
    this.footBuilder,
    this.headerBuilder,
    this.columnConstraints = const BoxConstraints(maxWidth: 200),
    Key? key,
  })  : phantomController = BoardPhantomController(delegate: dataController),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: dataController,
      child: Consumer<BoardDataController>(
        builder: (context, notifier, child) {
          List<Widget> children = dataController.columnDatas.map((columnData) {
            final controller = dataController.columnController(columnData.id);

            return _buildColumn(
              columnData.id,
              dataController.columnIds,
              controller,
            );
          }).toList();

          return BoardColumnContainer(
            onReorder: dataController.onReorder,
            boardDataController: dataController,
            background: background,
            spacing: spacing,
            delegate: phantomController,
            children: children,
          );
        },
      ),
    );
  }

  ///
  Widget _buildColumn(
    String columnId,
    List<String> acceptColumns,
    BoardColumnDataController dataController,
  ) {
    return ChangeNotifierProvider.value(
      key: ValueKey(columnId),
      value: dataController,
      child: Consumer<BoardColumnDataController>(
        builder: (context, value, child) {
          return ConstrainedBox(
            constraints: columnConstraints,
            child: BoardColumnWidget(
              headerBuilder: headerBuilder,
              footBuilder: footBuilder,
              cardBuilder: cardBuilder,
              acceptedColumns: acceptColumns,
              dataController: dataController,
              scrollController: ScrollController(),
              onReorder: (_, int fromIndex, int toIndex) {
                dataController.move(fromIndex, toIndex);
              },
              phantomController: phantomController,
            ),
          );
        },
      ),
    );
  }
}

class BoardDataController extends ChangeNotifier
    with EquatableMixin, BoardPhantomControllerDelegate, ReoderFlextDataSource {
  final List<BoardColumnData> _columnDatas = [];

  List<BoardColumnData> get columnDatas => _columnDatas;

  List<String> get columnIds =>
      _columnDatas.map((columnData) => columnData.id).toList();

  final LinkedHashMap<String, BoardColumnDataController> _columnControllers =
      LinkedHashMap();

  BoardDataController();

  void setColumnData(BoardColumnData columnData) {
    final controller = BoardColumnDataController(columnData: columnData);
    _columnDatas.add(columnData);
    _columnControllers[columnData.id] = controller;
  }

  BoardColumnDataController columnController(String columnId) {
    return _columnControllers[columnId]!;
  }

  void onReorder(int fromIndex, int toIndex) {
    final columnData = _columnDatas.removeAt(fromIndex);
    _columnDatas.insert(toIndex, columnData);
    notifyListeners();
  }

  @override
  List<Object?> get props {
    return [_columnDatas];
  }

  @override
  BoardColumnDataController? controller(String columnId) {
    return _columnControllers[columnId];
  }

  @override
  String get identifier => '$BoardDataController';

  @override
  List<ReoderFlexItem> get items => _columnDatas;
}

class BoardColumnContainer extends StatefulWidget {
  final ScrollController? scrollController;
  final OnDragStarted? onDragStarted;
  final OnReorder onReorder;
  final OnDragEnded? onDragEnded;
  final BoardDataController boardDataController;
  final List<Widget> children;
  final Widget? background;
  final double spacing;
  final ReorderFlexConfig config;

  final OverlapReorderFlexDragTargetDelegate delegate;

  const BoardColumnContainer({
    required this.onReorder,
    required this.children,
    required this.delegate,
    required this.boardDataController,
    this.onDragStarted,
    this.onDragEnded,
    this.scrollController,
    this.background,
    this.spacing = 0.0,
    this.config = const ReorderFlexConfig(),
    Key? key,
  }) : super(key: key);

  @override
  State<BoardColumnContainer> createState() => _BoardColumnContainerState();
}

class _BoardColumnContainerState extends State<BoardColumnContainer> {
  final GlobalKey _columnContainerOverlayKey =
      GlobalKey(debugLabel: '$BoardColumnContainer overlay key');
  late BoardOverlayEntry _overlayEntry;

  @override
  void initState() {
    _overlayEntry = BoardOverlayEntry(
      builder: (BuildContext context) {
        final interceptor = OverlapReorderFlexDragTargetInteceptor(
          reorderFlexId: widget.boardDataController.identifier,
          acceptedReorderFlexId: widget.boardDataController.columnIds,
          delegate: widget.delegate,
        );

        Widget reorderFlex = ReorderFlex(
          key: widget.key,
          scrollController: widget.scrollController,
          config: widget.config,
          onDragStarted: widget.onDragStarted,
          onReorder: widget.onReorder,
          onDragEnded: widget.onDragEnded,
          dataSource: widget.boardDataController,
          direction: Axis.horizontal,
          spacing: widget.spacing,
          interceptor: interceptor,
          children: widget.children,
        );

        return _wrapStack(reorderFlex);
      },
      opaque: false,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BoardOverlay(
      key: _columnContainerOverlayKey,
      initialEntries: [_overlayEntry],
    );
  }

  Widget _wrapStack(Widget child) {
    return Stack(
      alignment: AlignmentDirectional.topStart,
      children: [
        if (widget.background != null) widget.background!,
        child,
      ],
    );
  }
}
