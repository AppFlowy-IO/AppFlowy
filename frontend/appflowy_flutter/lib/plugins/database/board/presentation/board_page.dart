import 'dart:collection';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/board/mobile_board_content.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_state_container.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/board/presentation/widgets/board_column_header.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/plugins/database/tab_bar/desktop/setting_menu.dart';
import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:appflowy/plugins/database/widgets/card/card_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_style_maps/desktop_board_card_cell_style.dart';
import 'package:appflowy/plugins/database/widgets/row/row_detail.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../workspace/application/view/view_bloc.dart';
import '../../widgets/card/card.dart';
import '../../widgets/cell/card_cell_builder.dart';
import '../application/board_bloc.dart';
import 'toolbar/board_setting_bar.dart';
import 'widgets/board_hidden_groups.dart';

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
      BoardPage(view: view, databaseController: controller);

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
        builder: (context, state) => state.loadingState.when(
          loading: () => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
          idle: () => const SizedBox.shrink(),
          finish: (result) => result.fold(
            (_) => PlatformExtension.isMobile
                ? const MobileBoardContent()
                : DesktopBoardContent(onEditStateChanged: onEditStateChanged),
            (err) => PlatformExtension.isMobile
                ? FlowyMobileStateContainer.error(
                    emoji: '🛸',
                    title: LocaleKeys.board_mobile_failedToLoad.tr(),
                    errorMsg: err.toString(),
                  )
                : FlowyErrorPage.message(
                    err.toString(),
                    howToFix: LocaleKeys.errorDialog_howToFixFallback.tr(),
                  ),
          ),
        ),
      ),
    );
  }
}

class DesktopBoardContent extends StatefulWidget {
  const DesktopBoardContent({
    super.key,
    this.onEditStateChanged,
  });

  final VoidCallback? onEditStateChanged;

  @override
  State<DesktopBoardContent> createState() => _DesktopBoardContentState();
}

class _DesktopBoardContentState extends State<DesktopBoardContent> {
  final ScrollController scrollController = ScrollController();
  final AppFlowyBoardScrollController scrollManager =
      AppFlowyBoardScrollController();

  final config = const AppFlowyBoardConfig(
    groupMargin: EdgeInsets.symmetric(horizontal: 4),
    groupBodyPadding: EdgeInsets.symmetric(horizontal: 4),
    groupFooterPadding: EdgeInsets.fromLTRB(4, 14, 4, 4),
    groupHeaderPadding: EdgeInsets.symmetric(horizontal: 8),
    cardMargin: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    stretchGroupHeight: false,
  );

  late final cellBuilder = CardCellBuilder(
    databaseController: context.read<BoardBloc>().databaseController,
  );

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BoardBloc, BoardState>(
      listener: (context, state) {
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
              config: config,
              leading: HiddenGroupsColumn(margin: config.groupHeaderPadding),
              trailing: showCreateGroupButton
                  ? BoardTrailing(scrollController: scrollController)
                  : const HSpace(40),
              headerBuilder: (_, groupData) => BlocProvider<BoardBloc>.value(
                value: context.read<BoardBloc>(),
                child: BoardColumnHeader(
                  groupData: groupData,
                  margin: config.groupHeaderPadding,
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

  Widget _buildFooter(BuildContext context, AppFlowyGroupData columnData) {
    return Padding(
      padding: config.groupFooterPadding,
      child: FlowyTooltip(
        message: LocaleKeys.board_column_addToColumnBottomTooltip.tr(),
        child: FlowyHover(
          child: AppFlowyGroupFooter(
            height: 36,
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
          ),
        ),
      ),
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
    final rowCache = boardBloc.getRowCache();
    final rowInfo = rowCache?.getRow(groupItem.row.id);

    /// Return placeholder widget if the rowCache or rowInfo is null.
    if (rowCache == null) {
      return SizedBox.shrink(key: ObjectKey(groupItem));
    }

    final databaseController = boardBloc.databaseController;
    final viewId = boardBloc.viewId;

    final isEditing = boardBloc.state.isEditingRow &&
        boardBloc.state.editingRow?.row.id == groupItem.row.id;

    final groupItemId = "${groupData.group.groupId}${groupItem.row.id}";
    final rowMeta = rowInfo?.rowMeta ?? groupItem.row;

    return Container(
      key: ValueKey(groupItemId),
      margin: config.cardMargin,
      decoration: _makeBoxDecoration(context),
      child: RowCard(
        fieldController: databaseController.fieldController,
        rowMeta: rowMeta,
        viewId: viewId,
        rowCache: rowCache,
        groupingFieldId: groupItem.fieldInfo.id,
        isEditing: isEditing,
        cellBuilder: cellBuilder,
        openCard: (context) => _openCard(
          context: context,
          databaseController: databaseController,
          groupId: groupData.group.groupId,
          rowMeta: context.read<CardBloc>().state.rowMeta,
        ),
        styleConfiguration: RowCardStyleConfiguration(
          cellStyleMap: desktopBoardCardCellStyleMap(context),
          // hoverStyle: HoverStyle(
          //   hoverColor: Theme.of(context).brightness == Brightness.light
          //       ? const Color(0x0F1F2329)
          //       : const Color(0x0FEFF4FB),
          // foregroundColorOnHover: Theme.of(context).colorScheme.onBackground,
          // ),
        ),
        onStartEditing: () =>
            boardBloc.add(BoardEvent.startEditingRow(groupData.group, rowMeta)),
        onEndEditing: () => boardBloc.add(BoardEvent.endEditingRow(rowMeta.id)),
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

  void _openCard({
    required BuildContext context,
    required DatabaseController databaseController,
    required String groupId,
    required RowMetaPB rowMeta,
  }) {
    final rowInfo = RowInfo(
      viewId: databaseController.viewId,
      fields:
          UnmodifiableListView(databaseController.fieldController.fieldInfos),
      rowMeta: rowMeta,
      rowId: rowMeta.id,
    );

    final rowController = RowController(
      rowMeta: rowInfo.rowMeta,
      viewId: rowInfo.viewId,
      rowCache: databaseController.rowCache,
      groupId: groupId,
    );

    FlowyOverlay.show(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ViewBloc>(),
        child: RowDetailPage(
          databaseController: databaseController,
          rowController: rowController,
        ),
      ),
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
