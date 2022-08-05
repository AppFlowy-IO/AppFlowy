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
            onReorder: dataController.moveColumn,
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

  BoardContent({
    required this.onReorder,
    required this.delegate,
    required this.dataController,
    this.onDragStarted,
    this.onDragEnded,
    this.scrollController,
    this.background,
    this.spacing = 10.0,
    required this.columnConstraints,
    required this.cardBuilder,
    this.footBuilder,
    this.headerBuilder,
    required this.phantomController,
    Key? key,
  })  : config = ReorderFlexConfig(spacing: spacing),
        super(key: key);

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
        final interceptor = OverlapReorderFlexDragTargetInteceptor(
          reorderFlexId: widget.dataController.identifier,
          acceptedReorderFlexId: widget.dataController.columnIds,
          delegate: widget.delegate,
        );

        final reorderFlex = ReorderFlex(
          key: widget.key,
          config: widget.config,
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

  List<Widget> _buildColumns() {
    final List<Widget> children = widget.dataController.columnDatas.map(
      (columnData) {
        final dataSource = _BoardColumnDataSourceImpl(
          columnId: columnData.id,
          dataController: widget.dataController,
        );

        return ChangeNotifierProvider.value(
          key: ValueKey(columnData.id),
          value: widget.dataController.columnController(columnData.id),
          child: Consumer<BoardColumnDataController>(
            builder: (context, value, child) {
              return ConstrainedBox(
                constraints: widget.columnConstraints,
                child: BoardColumnWidget(
                  headerBuilder: widget.headerBuilder,
                  footBuilder: widget.footBuilder,
                  cardBuilder: widget.cardBuilder,
                  dataSource: dataSource,
                  scrollController: ScrollController(),
                  phantomController: widget.phantomController,
                  onReorder: widget.dataController.moveColumnItem,
                  spacing: 10,
                ),
              );
            },
          ),
        );
      },
    ).toList();

    return children;
  }
}

class _BoardColumnDataSourceImpl extends BoardColumnDataDataSource {
  String columnId;
  final BoardDataController dataController;

  _BoardColumnDataSourceImpl({
    required this.columnId,
    required this.dataController,
  });

  @override
  BoardColumnData get columnData =>
      dataController.columnController(columnId).columnData;

  @override
  List<String> get acceptedColumnIds => dataController.columnIds;
}
