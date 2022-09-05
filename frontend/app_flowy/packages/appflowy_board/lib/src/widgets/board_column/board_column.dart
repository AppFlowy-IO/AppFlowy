import 'dart:collection';

import 'package:appflowy_board/src/widgets/reorder_flex/drag_state.dart';
import 'package:flutter/material.dart';
import '../../rendering/board_overlay.dart';
import '../../utils/log.dart';
import '../reorder_phantom/phantom_controller.dart';
import '../reorder_flex/reorder_flex.dart';
import '../reorder_flex/drag_target_interceptor.dart';
import 'board_column_data.dart';

typedef OnGroupDragStarted = void Function(int index);

typedef OnGroupDragEnded = void Function(String listId);

typedef OnGroupReorder = void Function(
  String listId,
  int fromIndex,
  int toIndex,
);

typedef OnGroupDeleted = void Function(String listId, int deletedIndex);

typedef OnGroupInserted = void Function(String listId, int insertedIndex);

typedef AppFlowyBoardCardBuilder = Widget Function(
  BuildContext context,
  AppFlowyBoardGroupData groupData,
  AppFlowyGroupItem item,
);

typedef AppFlowyBoardHeaderBuilder = Widget? Function(
  BuildContext context,
  AppFlowyBoardGroupData groupData,
);

typedef AppFlowyBoardFooterBuilder = Widget Function(
  BuildContext context,
  AppFlowyBoardGroupData groupData,
);

abstract class AppFlowyBoardGroupDataDataSource extends ReoderFlexDataSource {
  AppFlowyBoardGroupData get groupData;

  List<String> get acceptedGroupIds;

  @override
  String get identifier => groupData.id;

  @override
  UnmodifiableListView<AppFlowyGroupItem> get items => groupData.items;

  void debugPrint() {
    String msg = '[$AppFlowyBoardGroupDataDataSource] $groupData data: ';
    for (var element in items) {
      msg = '$msg$element,';
    }

    Log.debug(msg);
  }
}

/// [AppFlowyBoardGroupWidget] represents the column of the Board.
///
class AppFlowyBoardGroupWidget extends StatefulWidget {
  final AppFlowyBoardGroupDataDataSource dataSource;
  final ScrollController? scrollController;
  final ReorderFlexConfig config;
  final OnGroupDragStarted? onDragStarted;
  final OnGroupReorder onReorder;
  final OnGroupDragEnded? onDragEnded;

  final BoardPhantomController phantomController;

  String get groupId => dataSource.groupData.id;

  final AppFlowyBoardCardBuilder cardBuilder;

  final AppFlowyBoardHeaderBuilder? headerBuilder;

  final AppFlowyBoardFooterBuilder? footerBuilder;

  final EdgeInsets margin;

  final EdgeInsets itemMargin;

  final double cornerRadius;

  final Color backgroundColor;

  final DraggingStateStorage? dragStateStorage;

  final ReorderDragTargetIndexKeyStorage? dragTargetIndexKeyStorage;

  final GlobalObjectKey reorderFlexKey;

  const AppFlowyBoardGroupWidget({
    Key? key,
    required this.reorderFlexKey,
    this.headerBuilder,
    this.footerBuilder,
    required this.cardBuilder,
    required this.onReorder,
    required this.dataSource,
    required this.phantomController,
    this.dragStateStorage,
    this.dragTargetIndexKeyStorage,
    this.scrollController,
    this.onDragStarted,
    this.onDragEnded,
    this.margin = EdgeInsets.zero,
    this.itemMargin = EdgeInsets.zero,
    this.cornerRadius = 0.0,
    this.backgroundColor = Colors.transparent,
  })  : config = const ReorderFlexConfig(setStateWhenEndDrag: false),
        super(key: key);

  @override
  State<AppFlowyBoardGroupWidget> createState() =>
      _AppFlowyBoardGroupWidgetState();
}

class _AppFlowyBoardGroupWidgetState extends State<AppFlowyBoardGroupWidget> {
  final GlobalKey _columnOverlayKey =
      GlobalKey(debugLabel: '$AppFlowyBoardGroupWidget overlay key');
  late BoardOverlayEntry _overlayEntry;

  @override
  void initState() {
    _overlayEntry = BoardOverlayEntry(
      builder: (BuildContext context) {
        final children = widget.dataSource.groupData.items
            .map((item) => _buildWidget(context, item))
            .toList();

        final header =
            widget.headerBuilder?.call(context, widget.dataSource.groupData);

        final footer =
            widget.footerBuilder?.call(context, widget.dataSource.groupData);

        final interceptor = CrossReorderFlexDragTargetInterceptor(
          reorderFlexId: widget.groupId,
          delegate: widget.phantomController,
          acceptedReorderFlexIds: widget.dataSource.acceptedGroupIds,
          draggableTargetBuilder: PhantomDraggableBuilder(),
        );

        Widget reorderFlex = ReorderFlex(
          key: widget.reorderFlexKey,
          dragStateStorage: widget.dragStateStorage,
          dragTargetIndexKeyStorage: widget.dragTargetIndexKeyStorage,
          scrollController: widget.scrollController,
          config: widget.config,
          onDragStarted: (index) {
            widget.phantomController.groupStartDragging(widget.groupId);
            widget.onDragStarted?.call(index);
          },
          onReorder: ((fromIndex, toIndex) {
            if (widget.phantomController.isFromGroup(widget.groupId)) {
              widget.onReorder(widget.groupId, fromIndex, toIndex);
              widget.phantomController.transformIndex(fromIndex, toIndex);
            }
          }),
          onDragEnded: () {
            widget.phantomController.groupEndDragging(widget.groupId);
            widget.onDragEnded?.call(widget.groupId);
            widget.dataSource.debugPrint();
          },
          dataSource: widget.dataSource,
          interceptor: interceptor,
          children: children,
        );

        reorderFlex = Expanded(
          child: Padding(padding: widget.itemMargin, child: reorderFlex),
        );

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
              reorderFlex,
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

  Widget _buildWidget(BuildContext context, AppFlowyGroupItem item) {
    if (item is PhantomGroupItem) {
      return PassthroughPhantomWidget(
        key: UniqueKey(),
        opacity: widget.config.draggingWidgetOpacity,
        passthroughPhantomContext: item.phantomContext,
      );
    } else {
      return widget.cardBuilder(context, widget.dataSource.groupData, item);
    }
  }
}
