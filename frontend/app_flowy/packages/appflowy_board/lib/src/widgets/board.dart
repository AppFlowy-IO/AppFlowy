import 'package:appflowy_board/src/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'board_data.dart';
import 'board_group/group.dart';
import 'board_group/group_data.dart';
import 'reorder_flex/drag_state.dart';
import 'reorder_flex/drag_target_interceptor.dart';
import 'reorder_flex/reorder_flex.dart';
import 'reorder_phantom/phantom_controller.dart';
import '../rendering/board_overlay.dart';

class AppFlowyBoardScrollController {
  AppFlowyBoardState? _groupState;

  void scrollToBottom(String groupId,
      {void Function(BuildContext)? completed}) {
    _groupState?.reorderFlexActionMap[groupId]?.scrollToBottom(completed);
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
  /// The widget that will be rendered as the background of the board.
  final Widget? background;

  /// The [cardBuilder] function which will be invoked on each card build.
  /// The [cardBuilder] takes the [BuildContext],[AppFlowyGroupData] and
  /// the corresponding [AppFlowyGroupItem].
  ///
  /// must return a widget.
  final AppFlowyBoardCardBuilder cardBuilder;

  /// The [headerBuilder] function which will be invoked on each group build.
  /// The [headerBuilder] takes the [BuildContext] and [AppFlowyGroupData].
  ///
  /// must return a widget.
  final AppFlowyBoardHeaderBuilder? headerBuilder;

  /// The [footerBuilder] function which will be invoked on each group build.
  /// The [footerBuilder] takes the [BuildContext] and [AppFlowyGroupData].
  ///
  /// must return a widget.
  final AppFlowyBoardFooterBuilder? footerBuilder;

  /// A controller for [AppFlowyBoard] widget.
  ///
  /// A [AppFlowyBoardController] can be used to provide an initial value of
  /// the board by calling `addGroup` method with the passed in parameter
  /// [AppFlowyGroupData]. A [AppFlowyGroupData] represents one
  /// group data. Whenever the user modifies the board, this controller will
  /// update the corresponding group data.
  ///
  /// Also, you can register the callbacks that receive the changes. Check out
  /// the [AppFlowyBoardController] for more information.
  ///
  final AppFlowyBoardController controller;

  /// A constraints applied to [AppFlowyBoardGroup] widget.
  final BoxConstraints groupConstraints;

  /// A controller is used by the [ReorderFlex].
  ///
  /// The [ReorderFlex] will used the primary scrollController of the current
  /// [BuildContext] by using PrimaryScrollController.of(context).
  /// If the primary scrollController is null, we will assign a new [ScrollController].
  final ScrollController? scrollController;

  ///
  final AppFlowyBoardConfig config;

  /// A controller is used to control each group scroll actions.
  ///
  final AppFlowyBoardScrollController? boardScrollController;

  final AppFlowyBoardState _groupState = AppFlowyBoardState();

  late final BoardPhantomController _phantomController;

  AppFlowyBoard({
    required this.controller,
    required this.cardBuilder,
    this.background,
    this.footerBuilder,
    this.headerBuilder,
    this.scrollController,
    this.boardScrollController,
    this.groupConstraints = const BoxConstraints(maxWidth: 200),
    this.config = const AppFlowyBoardConfig(),
    Key? key,
  }) : super(key: key) {
    _phantomController = BoardPhantomController(
      delegate: controller,
      groupsState: _groupState,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<AppFlowyBoardController>(
        builder: (context, notifier, child) {
          if (boardScrollController != null) {
            boardScrollController!._groupState = _groupState;
          }

          return _AppFlowyBoardContent(
            config: config,
            dataController: controller,
            scrollController: scrollController,
            scrollManager: boardScrollController,
            groupState: _groupState,
            background: background,
            delegate: _phantomController,
            groupConstraints: groupConstraints,
            cardBuilder: cardBuilder,
            footerBuilder: footerBuilder,
            headerBuilder: headerBuilder,
            phantomController: _phantomController,
            onReorder: controller.moveGroup,
          );
        },
      ),
    );
  }
}

class _AppFlowyBoardContent extends StatefulWidget {
  final ScrollController? scrollController;
  final OnReorder onReorder;
  final AppFlowyBoardController dataController;
  final Widget? background;
  final AppFlowyBoardConfig config;
  final ReorderFlexConfig reorderFlexConfig;
  final BoxConstraints groupConstraints;
  final AppFlowyBoardScrollController? scrollManager;
  final AppFlowyBoardState groupState;
  final AppFlowyBoardCardBuilder cardBuilder;
  final AppFlowyBoardHeaderBuilder? headerBuilder;
  final AppFlowyBoardFooterBuilder? footerBuilder;
  final OverlapDragTargetDelegate delegate;
  final BoardPhantomController phantomController;

  const _AppFlowyBoardContent({
    required this.config,
    required this.onReorder,
    required this.delegate,
    required this.dataController,
    required this.scrollManager,
    required this.groupState,
    this.scrollController,
    this.background,
    required this.groupConstraints,
    required this.cardBuilder,
    this.footerBuilder,
    this.headerBuilder,
    required this.phantomController,
    Key? key,
  })  : reorderFlexConfig = const ReorderFlexConfig(
          direction: Axis.horizontal,
          dragDirection: Axis.horizontal,
        ),
        super(key: key);

  @override
  State<_AppFlowyBoardContent> createState() => _AppFlowyBoardContentState();
}

class _AppFlowyBoardContentState extends State<_AppFlowyBoardContent> {
  final GlobalKey _boardContentKey =
      GlobalKey(debugLabel: '$_AppFlowyBoardContent overlay key');
  late BoardOverlayEntry _overlayEntry;

  @override
  void initState() {
    _overlayEntry = BoardOverlayEntry(
      builder: (BuildContext context) {
        final interceptor = OverlappingDragTargetInterceptor(
          reorderFlexId: widget.dataController.identifier,
          acceptedReorderFlexId: widget.dataController.groupIds,
          delegate: widget.delegate,
          columnsState: widget.groupState,
        );

        final reorderFlex = ReorderFlex(
          config: widget.reorderFlexConfig,
          scrollController: widget.scrollController,
          onReorder: widget.onReorder,
          dataSource: widget.dataController,
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
        widget.dataController.groupDatas.asMap().entries.map(
      (item) {
        final columnData = item.value;
        final columnIndex = item.key;

        final dataSource = _BoardGroupDataSourceImpl(
          groupId: columnData.id,
          dataController: widget.dataController,
        );

        final reorderFlexAction = ReorderFlexActionImpl();
        widget.groupState.reorderFlexActionMap[columnData.id] =
            reorderFlexAction;

        return ChangeNotifierProvider.value(
          key: ValueKey(columnData.id),
          value: widget.dataController.getGroupController(columnData.id),
          child: Consumer<AppFlowyGroupController>(
            builder: (context, value, child) {
              final boardColumn = AppFlowyBoardGroup(
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
                dragStateStorage: widget.groupState,
                dragTargetKeys: widget.groupState,
                reorderFlexAction: reorderFlexAction,
              );

              return ConstrainedBox(
                constraints: widget.groupConstraints,
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
    AppFlowyGroupData groupData,
  ) {
    if (widget.headerBuilder == null) {
      return null;
    }
    return Selector<AppFlowyGroupController, AppFlowyGroupHeaderData>(
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

class _BoardGroupDataSourceImpl extends AppFlowyGroupDataDataSource {
  String groupId;
  final AppFlowyBoardController dataController;

  _BoardGroupDataSourceImpl({
    required this.groupId,
    required this.dataController,
  });

  @override
  AppFlowyGroupData get groupData =>
      dataController.getGroupController(groupId)!.groupData;

  @override
  List<String> get acceptedGroupIds => dataController.groupIds;
}

/// A context contains the group states including the draggingState.
///
/// [draggingState] represents the dragging state of the group.
class AppFlowyGroupContext {
  DraggingState? draggingState;
}

class AppFlowyBoardState extends DraggingStateStorage
    with ReorderDragTargeKeys {
  final Map<String, DraggingState> groupDragStates = {};
  final Map<String, Map<String, GlobalObjectKey>> groupDragTargetKeys = {};

  /// Quick access to the [AppFlowyBoardGroup], the [GlobalKey] is bind to the
  /// AppFlowyBoardGroup's [ReorderFlex] widget.
  final Map<String, ReorderFlexActionImpl> reorderFlexActionMap = {};

  @override
  DraggingState? readState(String reorderFlexId) {
    return groupDragStates[reorderFlexId];
  }

  @override
  void insertState(String reorderFlexId, DraggingState state) {
    Log.trace('$reorderFlexId Write dragging state: $state');
    groupDragStates[reorderFlexId] = state;
  }

  @override
  void removeState(String reorderFlexId) {
    groupDragStates.remove(reorderFlexId);
  }

  @override
  void insertDragTarget(
    String reorderFlexId,
    String key,
    GlobalObjectKey<State<StatefulWidget>> value,
  ) {
    Map<String, GlobalObjectKey>? group = groupDragTargetKeys[reorderFlexId];
    if (group == null) {
      group = {};
      groupDragTargetKeys[reorderFlexId] = group;
    }
    group[key] = value;
  }

  @override
  GlobalObjectKey<State<StatefulWidget>>? getDragTarget(
    String reorderFlexId,
    String key,
  ) {
    Map<String, GlobalObjectKey>? group = groupDragTargetKeys[reorderFlexId];
    if (group != null) {
      return group[key];
    } else {
      return null;
    }
  }

  @override
  void removeDragTarget(String reorderFlexId) {
    groupDragTargetKeys.remove(reorderFlexId);
  }
}

class ReorderFlexActionImpl extends ReorderFlexAction {}
