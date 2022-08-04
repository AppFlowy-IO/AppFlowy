import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'flex/drag_target_inteceptor.dart';
import 'flex/reorder_flex.dart';
import 'phantom/phantom_controller.dart';
import '../../flowy_board.dart';
import '../rendering/board_overlay.dart';

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
          return BoardContent(
            dataController: dataController,
            background: background,
            spacing: spacing,
            delegate: phantomController,
            columnConstraints: columnConstraints,
            cardBuilder: cardBuilder,
            footBuilder: footBuilder,
            headerBuilder: headerBuilder,
            phantomController: phantomController,
            onReorder: dataController.onReorder,
          );
        },
      ),
    );
  }
}

class BoardContent extends StatefulWidget {
  final ScrollController? scrollController;
  final OnDragStarted? onDragStarted;
  final OnReorder onReorder;
  final OnDragEnded? onDragEnded;
  final BoardDataController dataController;
  final Widget? background;
  final double spacing;
  final ReorderFlexConfig config;
  final BoxConstraints columnConstraints;

  ///
  final BoardColumnCardBuilder cardBuilder;

  ///
  final BoardColumnHeaderBuilder? headerBuilder;

  ///
  final BoardColumnFooterBuilder? footBuilder;

  final OverlapReorderFlexDragTargetDelegate delegate;

  final BoardPhantomController phantomController;

  const BoardContent({
    required this.onReorder,
    required this.delegate,
    required this.dataController,
    this.onDragStarted,
    this.onDragEnded,
    this.scrollController,
    this.background,
    this.spacing = 0.0,
    this.config = const ReorderFlexConfig(),
    required this.columnConstraints,
    required this.cardBuilder,
    this.footBuilder,
    this.headerBuilder,
    required this.phantomController,
    Key? key,
  }) : super(key: key);

  @override
  State<BoardContent> createState() => _BoardContentState();
}

class _BoardContentState extends State<BoardContent> {
  final GlobalKey _columnContainerOverlayKey =
      GlobalKey(debugLabel: '$BoardContent overlay key');
  late BoardOverlayEntry _overlayEntry;

  @override
  void initState() {
    _overlayEntry = BoardOverlayEntry(
      builder: (BuildContext context) {
        List<Widget> children =
            widget.dataController.columnDatas.map((columnData) {
          return _buildColumn(
            columnData.id,
            widget.dataController.columnIds,
            widget.dataController.columnController(columnData.id),
          );
        }).toList();

        final interceptor = OverlapReorderFlexDragTargetInteceptor(
          reorderFlexId: widget.dataController.identifier,
          acceptedReorderFlexId: widget.dataController.columnIds,
          delegate: widget.delegate,
        );

        Widget reorderFlex = ReorderFlex(
          key: widget.key,
          scrollController: widget.scrollController,
          config: widget.config,
          onDragStarted: widget.onDragStarted,
          onReorder: widget.onReorder,
          onDragEnded: widget.onDragEnded,
          dataSource: widget.dataController,
          direction: Axis.horizontal,
          spacing: widget.spacing,
          interceptor: interceptor,
          children: children,
        );

        return Stack(
          alignment: AlignmentDirectional.topStart,
          children: [
            if (widget.background != null) widget.background!,
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
      key: _columnContainerOverlayKey,
      initialEntries: [_overlayEntry],
    );
  }

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
            constraints: widget.columnConstraints,
            child: BoardColumnWidget(
              headerBuilder: widget.headerBuilder,
              footBuilder: widget.footBuilder,
              cardBuilder: widget.cardBuilder,
              acceptedColumns: acceptColumns,
              dataController: dataController,
              scrollController: ScrollController(),
              onReorder: (_, int fromIndex, int toIndex) {
                dataController.move(fromIndex, toIndex);
              },
              phantomController: widget.phantomController,
            ),
          );
        },
      ),
    );
  }
}
