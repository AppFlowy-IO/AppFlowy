import 'dart:io';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/board/mobile_board_page.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/board/application/board_actions_bloc.dart';
import 'package:appflowy/plugins/database/board/presentation/widgets/board_column_header.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/plugins/database/tab_bar/desktop/setting_menu.dart';
import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:appflowy/plugins/database/widgets/card/card_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_style_maps/desktop_board_card_cell_style.dart';
import 'package:appflowy/plugins/database/widgets/row/row_detail.dart';
import 'package:appflowy/shared/conditional_listenable_builder.dart';
import 'package:appflowy/shared/flowy_error_page.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_validator/string_validator.dart';
import 'package:metadata_fetch_plus/metadata_fetch_plus.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../widgets/card/card.dart';
import '../../widgets/cell/card_cell_builder.dart';
import '../application/board_bloc.dart';

import 'toolbar/board_setting_bar.dart';
import 'widgets/board_focus_scope.dart';
import 'widgets/board_hidden_groups.dart';
import 'widgets/board_shortcut_container.dart';

class BoardPageTabBarBuilderImpl extends DatabaseTabBarItemBuilder {
  final _toggleExtension = ToggleExtensionNotifier();

  @override
  Widget content(
    BuildContext context,
    ViewPB view,
    DatabaseController controller,
    bool shrinkWrap,
    String? initialRowId,
  ) =>
      UniversalPlatform.isDesktop
          ? DesktopBoardPage(
              key: _makeValueKey(controller),
              view: view,
              databaseController: controller,
            )
          : MobileBoardPage(
              key: _makeValueKey(controller),
              view: view,
              databaseController: controller,
            );

  @override
  Widget settingBar(BuildContext context, DatabaseController controller) =>
      BoardSettingBar(
        key: _makeValueKey(controller),
        databaseController: controller,
        toggleExtension: _toggleExtension,
      );

  @override
  Widget settingBarExtension(
    BuildContext context,
    DatabaseController controller,
  ) {
    return DatabaseViewSettingExtension(
      key: _makeValueKey(controller),
      viewId: controller.viewId,
      databaseController: controller,
      toggleExtension: _toggleExtension,
    );
  }

  @override
  void dispose() {
    _toggleExtension.dispose();
    super.dispose();
  }

  ValueKey _makeValueKey(DatabaseController controller) =>
      ValueKey(controller.viewId);
}

class DesktopBoardPage extends StatefulWidget {
  const DesktopBoardPage({
    super.key,
    required this.view,
    required this.databaseController,
    this.onEditStateChanged,
  });

  final ViewPB view;

  final DatabaseController databaseController;

  /// Called when edit state changed
  final VoidCallback? onEditStateChanged;

  @override
  State<DesktopBoardPage> createState() => _DesktopBoardPageState();
}

class _DesktopBoardPageState extends State<DesktopBoardPage> {
  late final AppFlowyBoardController _boardController = AppFlowyBoardController(
    onMoveGroup: (fromGroupId, fromIndex, toGroupId, toIndex) =>
        widget.databaseController.moveGroup(
      fromGroupId: fromGroupId,
      toGroupId: toGroupId,
    ),
    onMoveGroupItem: (groupId, fromIndex, toIndex) {
      final groupControllers = _boardBloc.groupControllers;
      final fromRow = groupControllers[groupId]?.rowAtIndex(fromIndex);
      final toRow = groupControllers[groupId]?.rowAtIndex(toIndex);
      if (fromRow != null) {
        widget.databaseController.moveGroupRow(
          fromRow: fromRow,
          toRow: toRow,
          fromGroupId: groupId,
          toGroupId: groupId,
        );
      }
    },
    onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
      final groupControllers = _boardBloc.groupControllers;
      final fromRow = groupControllers[fromGroupId]?.rowAtIndex(fromIndex);
      final toRow = groupControllers[toGroupId]?.rowAtIndex(toIndex);
      if (fromRow != null) {
        widget.databaseController.moveGroupRow(
          fromRow: fromRow,
          toRow: toRow,
          fromGroupId: fromGroupId,
          toGroupId: toGroupId,
        );
      }
    },
    onStartDraggingCard: (groupId, index) {
      final groupControllers = _boardBloc.groupControllers;
      final toRow = groupControllers[groupId]?.rowAtIndex(index);
      if (toRow != null) {
        _focusScope.clear();
      }
    },
  );

  late final _focusScope = BoardFocusScope(
    boardController: _boardController,
  );
  late final BoardBloc _boardBloc;
  late final BoardActionsCubit _boardActionsCubit;
  late final ValueNotifier<DidCreateRowResult?> _didCreateRow;

  @override
  void initState() {
    super.initState();
    _didCreateRow = ValueNotifier(null)..addListener(_handleDidCreateRow);
    _boardBloc = BoardBloc(
      databaseController: widget.databaseController,
      didCreateRow: _didCreateRow,
      boardController: _boardController,
    )..add(const BoardEvent.initial());
    _boardActionsCubit = BoardActionsCubit(
      databaseController: widget.databaseController,
    );
  }

  @override
  void dispose() {
    _focusScope.dispose();
    _boardBloc.close();
    _boardActionsCubit.close();
    _didCreateRow
      ..removeListener(_handleDidCreateRow)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BoardBloc>.value(
          value: _boardBloc,
        ),
        BlocProvider.value(
          value: _boardActionsCubit,
        ),
      ],
      child: BlocBuilder<BoardBloc, BoardState>(
        builder: (context, state) => state.maybeMap(
          loading: (_) => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
          error: (err) => Center(
            child: AppFlowyErrorPage(
              error: err.error,
            ),
          ),
          orElse: () => _BoardContent(
            onEditStateChanged: widget.onEditStateChanged,
            focusScope: _focusScope,
            boardController: _boardController,
          ),
        ),
      ),
    );
  }

  void _handleDidCreateRow() async {
    // work around: wait for the new card to be inserted into the board before enabling edit
    await Future.delayed(const Duration(milliseconds: 50));
    if (_didCreateRow.value != null) {
      final result = _didCreateRow.value!;
      switch (result.action) {
        case DidCreateRowAction.openAsPage:
          _boardActionsCubit.openCard(result.rowMeta);
          break;
        case DidCreateRowAction.startEditing:
          _boardActionsCubit.startEditingRow(
            GroupedRowId(
              groupId: result.groupId,
              rowId: result.rowMeta.id,
            ),
          );
          break;
        default:
          break;
      }
    }
  }
}

class _BoardContent extends StatefulWidget {
  const _BoardContent({
    required this.boardController,
    required this.focusScope,
    this.onEditStateChanged,
  });

  final AppFlowyBoardController boardController;
  final BoardFocusScope focusScope;
  final VoidCallback? onEditStateChanged;

  @override
  State<_BoardContent> createState() => _BoardContentState();
}

class _BoardContentState extends State<_BoardContent> {
  final ScrollController scrollController = ScrollController();
  final AppFlowyBoardScrollController scrollManager =
      AppFlowyBoardScrollController();

  final config = const AppFlowyBoardConfig(
    groupMargin: EdgeInsets.symmetric(horizontal: 4),
    groupBodyPadding: EdgeInsets.symmetric(horizontal: 4),
    groupFooterPadding: EdgeInsets.fromLTRB(8, 14, 8, 4),
    groupHeaderPadding: EdgeInsets.symmetric(horizontal: 8),
    cardMargin: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    stretchGroupHeight: false,
  );

  late final cellBuilder = CardCellBuilder(
    databaseController: databaseController,
  );

  DatabaseController get databaseController =>
      context.read<BoardBloc>().databaseController;

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BoardBloc, BoardState>(
          listener: (context, state) {
            state.maybeMap(
              ready: (value) {
                widget.onEditStateChanged?.call();
              },
              orElse: () {},
            );
          },
        ),
        BlocListener<BoardActionsCubit, BoardActionsState>(
          listener: (context, state) {
            state.maybeMap(
              openCard: (value) {
                _openCard(
                  context: context,
                  databaseController:
                      context.read<BoardBloc>().databaseController,
                  rowMeta: value.rowMeta,
                );
              },
              setFocus: (value) {
                widget.focusScope.focusedGroupedRows = value.groupedRowIds;
              },
              startEditingRow: (value) {
                widget.boardController.enableGroupDragging(false);
                widget.focusScope.clear();
              },
              endEditingRow: (value) {
                widget.boardController.enableGroupDragging(true);
              },
              orElse: () {},
            );
          },
        ),
      ],
      child: FocusScope(
        autofocus: true,
        child: BoardShortcutContainer(
          focusScope: widget.focusScope,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: AppFlowyBoard(
              boardScrollController: scrollManager,
              scrollController: scrollController,
              controller: context.read<BoardBloc>().boardController,
              groupConstraints: const BoxConstraints.tightFor(width: 256),
              config: config,
              leading: HiddenGroupsColumn(margin: config.groupHeaderPadding),
              trailing: context
                          .read<BoardBloc>()
                          .groupingFieldType
                          ?.canCreateNewGroup ??
                      false
                  ? BoardTrailing(scrollController: scrollController)
                  : const HSpace(40),
              headerBuilder: (_, groupData) => BlocProvider.value(
                value: context.read<BoardBloc>(),
                child: BoardColumnHeader(
                  databaseController: databaseController,
                  groupData: groupData,
                  margin: config.groupHeaderPadding,
                ),
              ),
              footerBuilder: (_, groupData) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(
                    value: context.read<BoardBloc>(),
                  ),
                  BlocProvider.value(
                    value: context.read<BoardActionsCubit>(),
                  ),
                ],
                child: BoardColumnFooter(
                  columnData: groupData,
                  boardConfig: config,
                  scrollManager: scrollManager,
                ),
              ),
              cardBuilder: (_, column, columnItem) => MultiBlocProvider(
                key: ValueKey("board_card_${column.id}_${columnItem.id}"),
                providers: [
                  BlocProvider<BoardBloc>.value(
                    value: context.read<BoardBloc>(),
                  ),
                  BlocProvider.value(
                    value: context.read<BoardActionsCubit>(),
                  ),
                ],
                child: _BoardCard(
                  afGroupData: column,
                  groupItem: columnItem as GroupItem,
                  boardConfig: config,
                  notifier: widget.focusScope,
                  cellBuilder: cellBuilder,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class BoardColumnFooter extends StatefulWidget {
  const BoardColumnFooter({
    super.key,
    required this.columnData,
    required this.boardConfig,
    required this.scrollManager,
  });

  final AppFlowyGroupData columnData;
  final AppFlowyBoardConfig boardConfig;
  final AppFlowyBoardScrollController scrollManager;

  @override
  State<BoardColumnFooter> createState() => _BoardColumnFooterState();
}

class _BoardColumnFooterState extends State<BoardColumnFooter> {
  final TextEditingController _textController = TextEditingController();
  late final FocusNode _focusNode;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (_focusNode.hasFocus &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _focusNode.unfocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    )..addListener(() {
        if (!_focusNode.hasFocus) {
          setState(() => _isCreating = false);
        }
      });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isCreating) {
        _focusNode.requestFocus();
      }
    });
    return Padding(
      padding: widget.boardConfig.groupFooterPadding,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child:
            _isCreating ? _createCardsTextField() : _startCreatingCardsButton(),
      ),
    );
  }

  Widget _createCardsTextField() {
    const nada = DoNothingAndStopPropagationIntent();
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): nada,
        const SingleActivator(LogicalKeyboardKey.arrowDown): nada,
        const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): nada,
        const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): nada,
        const SingleActivator(LogicalKeyboardKey.keyE): nada,
        const SingleActivator(LogicalKeyboardKey.keyN): nada,
        const SingleActivator(LogicalKeyboardKey.delete): nada,
        // const SingleActivator(LogicalKeyboardKey.backspace): nada,
        const SingleActivator(LogicalKeyboardKey.enter): nada,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): nada,
        const SingleActivator(LogicalKeyboardKey.comma): nada,
        const SingleActivator(LogicalKeyboardKey.period): nada,
        SingleActivator(
          LogicalKeyboardKey.arrowUp,
          shift: true,
          meta: Platform.isMacOS,
          control: !Platform.isMacOS,
        ): nada,
      },
      child: FlowyTextField(
        hintTextConstraints: const BoxConstraints(maxHeight: 36),
        controller: _textController,
        focusNode: _focusNode,
        onSubmitted: (name) async {
          final boardBloc = context.read<BoardBloc>();
          final fetchURL = boardBloc.databaseController.databaseLayoutSetting
                  ?.board.fetchUrlMetaData ??
              false;

          String? url;
          if (fetchURL && isURL(name)) {
            final data = await MetadataFetch.extract(name);
            if (data != null && data.title != null) {
              url = name;
              name = data.title!;
            }
          }

          if (mounted) {
            boardBloc.add(
              BoardEvent.createRow(
                widget.columnData.id,
                OrderObjectPositionTypePB.End,
                name,
                null,
                url: url,
              ),
            );
          }
          widget.scrollManager.scrollToBottom(widget.columnData.id);
          _textController.clear();
          _focusNode.requestFocus();
        },
      ),
    );
  }

  Widget _startCreatingCardsButton() {
    return BlocListener<BoardActionsCubit, BoardActionsState>(
      listener: (context, state) {
        state.maybeWhen(
          startCreateBottomRow: (groupId) {
            if (groupId == widget.columnData.id) {
              setState(() => _isCreating = true);
            }
          },
          orElse: () {},
        );
      },
      child: FlowyTooltip(
        message: LocaleKeys.board_column_addToColumnBottomTooltip.tr(),
        child: SizedBox(
          height: 36,
          child: FlowyButton(
            leftIcon: FlowySvg(
              FlowySvgs.add_s,
              color: Theme.of(context).hintColor,
            ),
            text: FlowyText.medium(
              LocaleKeys.board_column_createNewCard.tr(),
              color: Theme.of(context).hintColor,
            ),
            onTap: () {
              setState(() => _isCreating = true);
            },
          ),
        ),
      ),
    );
  }
}

class _BoardCard extends StatefulWidget {
  const _BoardCard({
    required this.afGroupData,
    required this.groupItem,
    required this.boardConfig,
    required this.cellBuilder,
    required this.notifier,
  });

  final AppFlowyGroupData afGroupData;
  final GroupItem groupItem;
  final AppFlowyBoardConfig boardConfig;
  final CardCellBuilder cellBuilder;
  final BoardFocusScope notifier;

  @override
  State<_BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends State<_BoardCard> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final boardBloc = context.read<BoardBloc>();
    final groupData = widget.afGroupData.customData as GroupData;
    final rowCache = boardBloc.rowCache;
    final databaseController = boardBloc.databaseController;
    final rowMeta =
        rowCache.getRow(widget.groupItem.id)?.rowMeta ?? widget.groupItem.row;

    const nada = DoNothingAndStopPropagationIntent();

    return BlocListener<BoardActionsCubit, BoardActionsState>(
      listener: (context, state) {
        state.maybeMap(
          startEditingRow: (value) {
            if (value.groupedRowId.rowId == widget.groupItem.id &&
                value.groupedRowId.groupId == groupData.group.groupId) {
              setState(() => _isEditing = true);
            }
          },
          endEditingRow: (_) {
            if (_isEditing) {
              setState(() => _isEditing = false);
            }
          },
          createRow: (value) {
            if ((_isEditing && value.groupedRowId == null) ||
                (value.groupedRowId?.rowId == widget.groupItem.id &&
                    value.groupedRowId?.groupId == groupData.group.groupId)) {
              context.read<BoardBloc>().add(
                    BoardEvent.createRow(
                      groupData.group.groupId,
                      value.position == CreateBoardCardRelativePosition.before
                          ? OrderObjectPositionTypePB.Before
                          : OrderObjectPositionTypePB.After,
                      null,
                      widget.groupItem.row.id,
                    ),
                  );
            }
          },
          orElse: () {},
        );
      },
      child: Shortcuts(
        shortcuts: {
          const SingleActivator(LogicalKeyboardKey.arrowUp): nada,
          const SingleActivator(LogicalKeyboardKey.arrowDown): nada,
          const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): nada,
          const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
              nada,
          const SingleActivator(LogicalKeyboardKey.keyE): nada,
          const SingleActivator(LogicalKeyboardKey.keyN): nada,
          const SingleActivator(LogicalKeyboardKey.delete): nada,
          // const SingleActivator(LogicalKeyboardKey.backspace): nada,
          const SingleActivator(LogicalKeyboardKey.enter): nada,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): nada,
          const SingleActivator(LogicalKeyboardKey.comma): nada,
          const SingleActivator(LogicalKeyboardKey.period): nada,
          SingleActivator(
            LogicalKeyboardKey.arrowUp,
            shift: true,
            meta: Platform.isMacOS,
            control: !Platform.isMacOS,
          ): nada,
        },
        child: ConditionalListenableBuilder<List<GroupedRowId>>(
          valueListenable: widget.notifier,
          buildWhen: (previous, current) {
            final focusItem = GroupedRowId(
              groupId: groupData.group.groupId,
              rowId: rowMeta.id,
            );
            final previousContainsFocus = previous.contains(focusItem);
            final currentContainsFocus = current.contains(focusItem);

            return previousContainsFocus != currentContainsFocus;
          },
          builder: (context, focusedItems, child) => Container(
            margin: widget.boardConfig.cardMargin,
            decoration: _makeBoxDecoration(
              context,
              groupData.group.groupId,
              widget.groupItem.id,
            ),
            child: child,
          ),
          child: RowCard(
            fieldController: databaseController.fieldController,
            rowMeta: rowMeta,
            viewId: boardBloc.viewId,
            rowCache: rowCache,
            groupingFieldId: widget.groupItem.fieldInfo.id,
            isEditing: _isEditing,
            cellBuilder: widget.cellBuilder,
            onTap: (context) => _openCard(
              context: context,
              databaseController: databaseController,
              rowMeta: context.read<CardBloc>().rowController.rowMeta,
            ),
            onShiftTap: (_) {
              Focus.of(context).requestFocus();
              widget.notifier.toggle(
                GroupedRowId(
                  rowId: widget.groupItem.row.id,
                  groupId: groupData.group.groupId,
                ),
              );
            },
            styleConfiguration: RowCardStyleConfiguration(
              cellStyleMap: desktopBoardCardCellStyleMap(context),
              hoverStyle: HoverStyle(
                hoverColor: Theme.of(context).brightness == Brightness.light
                    ? const Color(0x0F1F2329)
                    : const Color(0x0FEFF4FB),
                foregroundColorOnHover:
                    AFThemeExtension.of(context).onBackground,
              ),
            ),
            onStartEditing: () =>
                context.read<BoardActionsCubit>().startEditingRow(
                      GroupedRowId(
                        groupId: groupData.group.groupId,
                        rowId: rowMeta.id,
                      ),
                    ),
            onEndEditing: () => context.read<BoardActionsCubit>().endEditing(
                  GroupedRowId(
                    groupId: groupData.group.groupId,
                    rowId: rowMeta.id,
                  ),
                ),
            userProfile: context.read<BoardBloc>().userProfile,
          ),
        ),
      ),
    );
  }

  BoxDecoration _makeBoxDecoration(
    BuildContext context,
    String groupId,
    String rowId,
  ) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      border: Border.fromBorderSide(
        BorderSide(
          color: widget.notifier
                  .isFocused(GroupedRowId(rowId: rowId, groupId: groupId))
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF1F2329).withOpacity(0.12)
                  : const Color(0xFF59647A),
        ),
      ),
      boxShadow: [
        BoxShadow(
          blurRadius: 4,
          color: const Color(0xFF1F2329).withOpacity(0.02),
        ),
        BoxShadow(
          blurRadius: 4,
          spreadRadius: -2,
          color: const Color(0xFF1F2329).withOpacity(0.02),
        ),
      ],
    );
  }
}

class BoardTrailing extends StatefulWidget {
  const BoardTrailing({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  State<BoardTrailing> createState() => _BoardTrailingState();
}

class _BoardTrailingState extends State<BoardTrailing> {
  final TextEditingController _textController = TextEditingController();
  late final FocusNode _focusNode;

  bool isEditing = false;

  void _cancelAddNewGroup() {
    _textController.clear();
    setState(() => isEditing = false);
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (_focusNode.hasFocus &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _cancelAddNewGroup();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    )..addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // call after every setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isEditing) {
        _focusNode.requestFocus();
        widget.scrollController.jumpTo(
          widget.scrollController.position.maxScrollExtent,
        );
      }
    });

    return Container(
      padding: const EdgeInsets.only(left: 8.0, top: 12, right: 40),
      alignment: AlignmentDirectional.topStart,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isEditing
            ? SizedBox(
                width: 256,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8.0),
                        child: FlowyIconButton(
                          icon: const FlowySvg(FlowySvgs.close_filled_m),
                          hoverColor: Colors.transparent,
                          onPressed: () => _textController.clear(),
                        ),
                      ),
                      suffixIconConstraints:
                          BoxConstraints.loose(const Size(20, 24)),
                      border: const UnderlineInputBorder(),
                      contentPadding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      isDense: true,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                    onSubmitted: (groupName) => context
                        .read<BoardBloc>()
                        .add(BoardEvent.createGroup(groupName)),
                  ),
                ),
              )
            : FlowyTooltip(
                message: LocaleKeys.board_column_createNewColumn.tr(),
                child: FlowyIconButton(
                  width: 26,
                  icon: const FlowySvg(FlowySvgs.add_s),
                  iconColorOnHover: Theme.of(context).colorScheme.onSurface,
                  onPressed: () => setState(() => isEditing = true),
                ),
              ),
      ),
    );
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _cancelAddNewGroup();
    }
  }
}

void _openCard({
  required BuildContext context,
  required DatabaseController databaseController,
  required RowMetaPB rowMeta,
}) {
  final rowController = RowController(
    rowMeta: rowMeta,
    viewId: databaseController.viewId,
    rowCache: databaseController.rowCache,
  );

  FlowyOverlay.show(
    context: context,
    builder: (_) => RowDetailPage(
      databaseController: databaseController,
      rowController: rowController,
      userProfile: context.read<BoardBloc>().userProfile,
    ),
  );
}
