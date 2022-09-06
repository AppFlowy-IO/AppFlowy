import 'package:appflowy_board/src/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'board_column/board_column.dart';
import 'board_column/board_column_data.dart';
import 'board_data.dart';
import 'reorder_flex/drag_state.dart';
import 'reorder_flex/drag_target_interceptor.dart';
import 'reorder_flex/reorder_flex.dart';
import 'reorder_phantom/phantom_controller.dart';
import '../rendering/board_overlay.dart';

class AFBoardScrollManager {
  BoardGroupsState? _groupState;

  void scrollToBottom(String groupId, VoidCallback? completed) {
    _groupState
        ?.getReorderFlexState(groupId: groupId)
        ?.scrollToBottom(completed);
  }
}

class AppFlowyBoardConfig {
  final double cornerRadius;
  final EdgeInsets groupPadding;
  final EdgeInsets groupItemPadding;
  final EdgeInsets footerPadding;
  final EdgeInsets headerPadding;
  final EdgeInsets cardPadding;
  final Color groupBackgroundColor;

  const AppFlowyBoardConfig({
    this.cornerRadius = 6.0,
    this.groupPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.groupItemPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.footerPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.cardPadding = const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
    this.groupBackgroundColor = Colors.transparent,
  });
}

class AppFlowyBoard extends StatelessWidget {
  /// The direction to use as the main axis.
  final Axis direction = Axis.vertical;

  /// The widget that will be rendered as the background of the board.
  final Widget? background;

  /// The [cardBuilder] function which will be invoked on each card build.
  /// The [cardBuilder] takes the [BuildContext],[AppFlowyBoardGroupData] and
  /// the corresponding [AppFlowyGroupItem].
  ///
  /// must return a widget.
  final AppFlowyBoardCardBuilder cardBuilder;

  /// The [headerBuilder] function which will be invoked on each group build.
  /// The [headerBuilder] takes the [BuildContext] and [AppFlowyBoardGroupData].
  ///
  /// must return a widget.
  final AppFlowyBoardHeaderBuilder? headerBuilder;

  /// The [footerBuilder] function which will be invoked on each group build.
  /// The [footerBuilder] takes the [BuildContext] and [AppFlowyBoardGroupData].
  ///
  /// must return a widget.
  final AppFlowyBoardFooterBuilder? footerBuilder;

  ///
  final AppFlowyBoardDataController dataController;

  final BoxConstraints groupConstraints;

  ///
  late final BoardPhantomController phantomController;

  final ScrollController? scrollController;

  final AppFlowyBoardConfig config;

  final AFBoardScrollManager? scrollManager;

  final BoardGroupsState _groupState = BoardGroupsState();

  AppFlowyBoard({
    required this.dataController,
    required this.cardBuilder,
    this.background,
    this.footerBuilder,
    this.headerBuilder,
    this.scrollController,
    this.scrollManager,
    this.groupConstraints = const BoxConstraints(maxWidth: 200),
    this.config = const AppFlowyBoardConfig(),
    Key? key,
  }) : super(key: key) {
    phantomController = BoardPhantomController(
      delegate: dataController,
      groupsState: _groupState,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: dataController,
      child: Consumer<AppFlowyBoardDataController>(
        builder: (context, notifier, child) {
          if (scrollManager != null) {
            scrollManager!._groupState = _groupState;
          }

          return _AppFlolwyBoardContent(
            config: config,
            dataController: dataController,
            scrollController: scrollController,
            scrollManager: scrollManager,
            columnsState: _groupState,
            background: background,
            delegate: phantomController,
            columnConstraints: groupConstraints,
            cardBuilder: cardBuilder,
            footerBuilder: footerBuilder,
            headerBuilder: headerBuilder,
            phantomController: phantomController,
            onReorder: dataController.moveGroup,
          );
        },
      ),
    );
  }
}

class _AppFlolwyBoardContent extends StatefulWidget {
  final ScrollController? scrollController;
  final OnDragStarted? onDragStarted;
  final OnReorder onReorder;
  final OnDragEnded? onDragEnded;
  final AppFlowyBoardDataController dataController;
  final Widget? background;
  final AppFlowyBoardConfig config;
  final ReorderFlexConfig reorderFlexConfig;
  final BoxConstraints columnConstraints;
  final AFBoardScrollManager? scrollManager;
  final BoardGroupsState columnsState;
  final AppFlowyBoardCardBuilder cardBuilder;
  final AppFlowyBoardHeaderBuilder? headerBuilder;
  final AppFlowyBoardFooterBuilder? footerBuilder;
  final OverlapDragTargetDelegate delegate;
  final BoardPhantomController phantomController;

  const _AppFlolwyBoardContent({
    required this.config,
    required this.onReorder,
    required this.delegate,
    required this.dataController,
    required this.scrollManager,
    required this.columnsState,
    this.onDragStarted,
    this.onDragEnded,
    this.scrollController,
    this.background,
    required this.columnConstraints,
    required this.cardBuilder,
    this.footerBuilder,
    this.headerBuilder,
    required this.phantomController,
    Key? key,
  })  : reorderFlexConfig = const ReorderFlexConfig(),
        super(key: key);

  @override
  State<_AppFlolwyBoardContent> createState() => _AppFlowyBoardContentState();
}

class _AppFlowyBoardContentState extends State<_AppFlolwyBoardContent> {
  final GlobalKey _boardContentKey =
      GlobalKey(debugLabel: '$_AppFlolwyBoardContent overlay key');
  late BoardOverlayEntry _overlayEntry;

  final Map<String, GlobalObjectKey> _reorderFlexKeys = {};

  @override
  void initState() {
    _overlayEntry = BoardOverlayEntry(
      builder: (BuildContext context) {
        final interceptor = OverlappingDragTargetInterceptor(
          reorderFlexId: widget.dataController.identifier,
          acceptedReorderFlexId: widget.dataController.groupIds,
          delegate: widget.delegate,
          columnsState: widget.columnsState,
        );

        final reorderFlex = ReorderFlex(
          config: widget.reorderFlexConfig,
          scrollController: widget.scrollController,
          onDragStarted: widget.onDragStarted,
          onReorder: widget.onReorder,
          onDragEnded: widget.onDragEnded,
          dataSource: widget.dataController,
          direction: Axis.horizontal,
          interceptor: interceptor,
          reorderable: false,
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
        widget.dataController.groupDatas.asMap().entries.map(
      (item) {
        final columnData = item.value;
        final columnIndex = item.key;

        final dataSource = _BoardGroupDataSourceImpl(
          groupId: columnData.id,
          dataController: widget.dataController,
        );

        if (_reorderFlexKeys[columnData.id] == null) {
          _reorderFlexKeys[columnData.id] = GlobalObjectKey(columnData.id);
        }

        GlobalObjectKey reorderFlexKey = _reorderFlexKeys[columnData.id]!;
        return ChangeNotifierProvider.value(
          key: ValueKey(columnData.id),
          value: widget.dataController.getGroupController(columnData.id),
          child: Consumer<AFBoardGroupDataController>(
            builder: (context, value, child) {
              final boardColumn = AppFlowyBoardGroup(
                reorderFlexKey: reorderFlexKey,
                // key: PageStorageKey<String>(columnData.id),
                margin: _marginFromIndex(columnIndex),
                itemMargin: widget.config.groupItemPadding,
                headerBuilder: _buildHeader,
                footerBuilder: widget.footerBuilder,
                cardBuilder: widget.cardBuilder,
                dataSource: dataSource,
                scrollController: ScrollController(),
                phantomController: widget.phantomController,
                onReorder: widget.dataController.moveGroupItem,
                cornerRadius: widget.config.cornerRadius,
                backgroundColor: widget.config.groupBackgroundColor,
                dragStateStorage: widget.columnsState,
                dragTargetIndexKeyStorage: widget.columnsState,
              );

              widget.columnsState.addGroup(columnData.id, boardColumn);
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
    BuildContext context,
    AppFlowyBoardGroupData groupData,
  ) {
    if (widget.headerBuilder == null) {
      return null;
    }
    return Selector<AFBoardGroupDataController, AppFlowyBoardGroupHeaderData>(
      selector: (context, controller) => controller.groupData.headerData,
      builder: (context, headerData, _) {
        return widget.headerBuilder!(context, groupData)!;
      },
    );
  }

  EdgeInsets _marginFromIndex(int index) {
    if (widget.dataController.groupDatas.isEmpty) {
      return widget.config.groupPadding;
    }

    if (index == 0) {
      return EdgeInsets.only(right: widget.config.groupPadding.right);
    }

    if (index == widget.dataController.groupDatas.length - 1) {
      return EdgeInsets.only(left: widget.config.groupPadding.left);
    }

    return widget.config.groupPadding;
  }
}

class _BoardGroupDataSourceImpl extends AppFlowyBoardGroupDataDataSource {
  String groupId;
  final AppFlowyBoardDataController dataController;

  _BoardGroupDataSourceImpl({
    required this.groupId,
    required this.dataController,
  });

  @override
  AppFlowyBoardGroupData get groupData =>
      dataController.getGroupController(groupId)!.groupData;

  @override
  List<String> get acceptedGroupIds => dataController.groupIds;
}

class BoardGroupContext {
  GlobalKey? groupKey;
  DraggingState? draggingState;
}

class BoardGroupsState extends DraggingStateStorage
    with ReorderDragTargetIndexKeyStorage {
  /// Quick access to the [AppFlowyBoardGroup]
  final Map<String, GlobalKey> groupKeys = {};
  final Map<String, DraggingState> groupDragStates = {};
  final Map<String, Map<String, GlobalObjectKey>> groupDragDragTargets = {};

  void addGroup(String groupId, AppFlowyBoardGroup groupWidget) {
    groupKeys[groupId] = groupWidget.reorderFlexKey;
  }

  ReorderFlexState? getReorderFlexState({required String groupId}) {
    final flexGlobalKey = groupKeys[groupId];
    if (flexGlobalKey == null) return null;
    if (flexGlobalKey.currentState is! ReorderFlexState) return null;
    final state = flexGlobalKey.currentState as ReorderFlexState;
    return state;
  }

  ReorderFlex? getReorderFlex({required String groupId}) {
    final flexGlobalKey = groupKeys[groupId];
    if (flexGlobalKey == null) return null;
    if (flexGlobalKey.currentWidget is! ReorderFlex) return null;
    final widget = flexGlobalKey.currentWidget as ReorderFlex;
    return widget;
  }

  @override
  DraggingState? read(String reorderFlexId) {
    return groupDragStates[reorderFlexId];
  }

  @override
  void write(String reorderFlexId, DraggingState state) {
    Log.trace('$reorderFlexId Write dragging state: $state');
    groupDragStates[reorderFlexId] = state;
  }

  @override
  void remove(String reorderFlexId) {
    groupDragStates.remove(reorderFlexId);
  }

  @override
  void addKey(
    String reorderFlexId,
    String key,
    GlobalObjectKey<State<StatefulWidget>> value,
  ) {
    Map<String, GlobalObjectKey>? group = groupDragDragTargets[reorderFlexId];
    if (group == null) {
      group = {};
      groupDragDragTargets[reorderFlexId] = group;
    }
    group[key] = value;
  }

  @override
  GlobalObjectKey<State<StatefulWidget>>? readKey(
      String reorderFlexId, String key) {
    Map<String, GlobalObjectKey>? group = groupDragDragTargets[reorderFlexId];
    if (group != null) {
      return group[key];
    } else {
      return null;
    }
  }
}
