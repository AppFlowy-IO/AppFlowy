import 'dart:collection';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/board/presentation/widgets/board_column_header.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/plugins/database_view/tab_bar/tab_bar_view.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_detail.dart';
import 'package:appflowy/util/platform_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/card/card.dart';
import '../../widgets/card/card_cell_builder.dart';
import '../../widgets/card/cells/card_cell.dart';
import '../../widgets/row/cell_builder.dart';
import '../application/board_bloc.dart';
import 'toolbar/board_setting_bar.dart';
import 'widgets/board_hidden_groups.dart';

class BoardPageTabBarBuilderImpl implements DatabaseTabBarItemBuilder {
  @override
  Widget content(
    BuildContext context,
    ViewPB view,
    DatabaseController controller,
    bool shrinkWrap,
  ) =>
      BoardPage(view: view, databaseController: controller);

  @override
  Widget settingBar(BuildContext context, DatabaseController controller) =>
      BoardSettingBar(
        key: _makeValueKey(controller),
        databaseController: controller,
      );

  @override
  Widget settingBarExtension(
    BuildContext context,
    DatabaseController controller,
  ) =>
      const SizedBox.shrink();

  ValueKey _makeValueKey(DatabaseController controller) =>
      ValueKey(controller.viewId);
}

class BoardPage extends StatelessWidget {
  BoardPage({
    required this.view,
    required this.databaseController,
    this.onEditStateChanged,
  }) : super(key: ValueKey(view.id));

  final ViewPB view;

  final DatabaseController databaseController;

  /// Called when edit state changed
  final VoidCallback? onEditStateChanged;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BoardBloc>(
      create: (context) => BoardBloc(
        view: view,
        databaseController: databaseController,
      )..add(const BoardEvent.initial()),
      child: BlocBuilder<BoardBloc, BoardState>(
        buildWhen: (p, c) => p.loadingState != c.loadingState,
        builder: (context, state) => state.loadingState.map(
          loading: (_) => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
          finish: (result) => result.successOrFail.fold(
            (_) => BoardContent(onEditStateChanged: onEditStateChanged),
            (err) => FlowyErrorPage.message(
              err.toString(),
              howToFix: LocaleKeys.errorDialog_howToFixFallback.tr(),
            ),
          ),
        ),
      ),
    );
  }
}

class BoardContent extends StatefulWidget {
  const BoardContent({
    super.key,
    this.onEditStateChanged,
  });

  final VoidCallback? onEditStateChanged;

  @override
  State<BoardContent> createState() => _BoardContentState();
}

class _BoardContentState extends State<BoardContent> {
  final renderHook = RowCardRenderHook<String>();
  late final ScrollController scrollController;
  late final AppFlowyBoardScrollController scrollManager;

  final config = const AppFlowyBoardConfig(
    groupBackgroundColor: Color(0xffF7F8FC),
    headerPadding: EdgeInsets.symmetric(horizontal: 8),
    cardPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
  );

  @override
  void initState() {
    super.initState();

    scrollManager = AppFlowyBoardScrollController();
    scrollController = ScrollController();
    renderHook.addSelectOptionHook((options, groupId, _) {
      // The cell should hide if the option id is equal to the groupId.
      final isInGroup =
          options.where((element) => element.id == groupId).isNotEmpty;

      if (isInGroup || options.isEmpty) {
        return const SizedBox.shrink();
      }

      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BoardBloc, BoardState>(
      listener: (context, state) {
        _handleEditStateChanged(state, context);
        widget.onEditStateChanged?.call();
      },
      child: BlocBuilder<BoardBloc, BoardState>(
        builder: (context, state) {
          final showCreateGroupButton =
              context.read<BoardBloc>().groupingFieldType.canCreateNewGroup;
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: AppFlowyBoard(
              boardScrollController: scrollManager,
              scrollController: scrollController,
              controller: context.read<BoardBloc>().boardController,
              groupConstraints: const BoxConstraints.tightFor(width: 256),
              config: const AppFlowyBoardConfig(
                groupPadding: EdgeInsets.symmetric(horizontal: 4),
                groupItemPadding: EdgeInsets.symmetric(horizontal: 4),
                footerPadding: EdgeInsets.fromLTRB(4, 14, 4, 4),
                stretchGroupHeight: false,
              ),
              leading: HiddenGroupsColumn(margin: config.headerPadding),
              trailing: showCreateGroupButton
                  ? BoardTrailing(scrollController: scrollController)
                  : null,
              headerBuilder: (_, groupData) => BlocProvider<BoardBloc>.value(
                value: context.read<BoardBloc>(),
                child: BoardColumnHeader(
                  groupData: groupData,
                  margin: config.headerPadding,
                ),
              ),
              footerBuilder: _buildFooter,
              cardBuilder: (_, column, columnItem) => _buildCard(
                context,
                column,
                columnItem,
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleEditStateChanged(BoardState state, BuildContext context) {
    if (state.isEditingRow && state.editingRow != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state.editingRow!.index == null) {
          scrollManager.scrollToBottom(state.editingRow!.group.groupId);
        }
      });
    }
  }

  Widget _buildFooter(BuildContext context, AppFlowyGroupData columnData) {
    return AppFlowyGroupFooter(
      height: 36,
      margin: config.footerPadding,
      icon: FlowySvg(
        FlowySvgs.add_s,
        color: Theme.of(context).hintColor,
      ),
      title: FlowyText.medium(
        LocaleKeys.board_column_createNewCard.tr(),
        color: Theme.of(context).hintColor,
      ),
      onAddButtonClick: () => context
          .read<BoardBloc>()
          .add(BoardEvent.createBottomRow(columnData.id)),
    );
  }

  Widget _buildCard(
    BuildContext context,
    AppFlowyGroupData afGroupData,
    AppFlowyGroupItem afGroupItem,
  ) {
    final boardBloc = context.read<BoardBloc>();
    final groupItem = afGroupItem as GroupItem;
    final groupData = afGroupData.customData as GroupData;
    final rowMeta = groupItem.row;
    final rowCache = boardBloc.getRowCache();

    /// Return placeholder widget if the rowCache is null.
    if (rowCache == null) return SizedBox.shrink(key: ObjectKey(groupItem));
    final cellCache = rowCache.cellCache;
    final fieldController = boardBloc.fieldController;
    final viewId = boardBloc.viewId;

    final cellBuilder = CardCellBuilder<String>(cellCache);
    final isEditing = boardBloc.state.isEditingRow &&
        boardBloc.state.editingRow?.row.id == groupItem.row.id;

    final groupItemId = groupItem.row.id + groupData.group.groupId;

    return AppFlowyGroupCard(
      key: ValueKey(groupItemId),
      margin: config.cardPadding,
      decoration: _makeBoxDecoration(context),
      child: RowCard<String>(
        rowMeta: rowMeta,
        viewId: viewId,
        rowCache: rowCache,
        cardData: groupData.group.groupId,
        groupingFieldId: groupItem.fieldInfo.id,
        groupId: groupData.group.groupId,
        isEditing: isEditing,
        cellBuilder: cellBuilder,
        renderHook: renderHook,
        openCard: (context) => _openCard(
          context: context,
          viewId: viewId,
          groupId: groupData.group.groupId,
          fieldController: fieldController,
          rowMeta: rowMeta,
          rowCache: rowCache,
        ),
        styleConfiguration: RowCardStyleConfiguration(
          hoverStyle: HoverStyle(
            hoverColor: Theme.of(context).brightness == Brightness.light
                ? const Color(0x0F1F2329)
                : const Color(0x0FEFF4FB),
            foregroundColorOnHover: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        onStartEditing: () => boardBloc
            .add(BoardEvent.startEditingRow(groupData.group, groupItem.row)),
        onEndEditing: () =>
            boardBloc.add(BoardEvent.endEditingRow(groupItem.row.id)),
      ),
    );
  }

  BoxDecoration _makeBoxDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      border: Border.fromBorderSide(
        BorderSide(
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFF1F2329).withOpacity(0.12)
              : const Color(0xFF59647A),
          width: 1.0,
        ),
      ),
      boxShadow: [
        BoxShadow(
          blurRadius: 4,
          spreadRadius: 0,
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

  void _openCard({
    required BuildContext context,
    required String viewId,
    required String groupId,
    required FieldController fieldController,
    required RowMetaPB rowMeta,
    required RowCache rowCache,
  }) {
    final rowInfo = RowInfo(
      viewId: viewId,
      fields: UnmodifiableListView(fieldController.fieldInfos),
      rowMeta: rowMeta,
      rowId: rowMeta.id,
    );

    final dataController = RowController(
      rowMeta: rowInfo.rowMeta,
      viewId: rowInfo.viewId,
      rowCache: rowCache,
      groupId: groupId,
    );

    // navigate to card detail screen when it is in mobile
    if (PlatformExtension.isMobile) {
      context.push(
        MobileCardDetailScreen.routeName,
        extra: {
          MobileCardDetailScreen.argRowController: dataController,
          MobileCardDetailScreen.argFieldController: fieldController,
        },
      );
    } else {
      FlowyOverlay.show(
        context: context,
        builder: (_) => RowDetailPage(
          fieldController: fieldController,
          cellBuilder: GridCellBuilder(cellCache: dataController.cellCache),
          rowController: dataController,
        ),
      );
    }
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

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 12),
      child: Align(
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
                      maxLines: 1,
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
      ),
    );
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _cancelAddNewGroup();
    }
  }
}
