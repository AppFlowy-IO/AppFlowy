import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/board/board.dart';
import 'package:appflowy/mobile/presentation/database/board/widgets/group_card_header.dart';
import 'package:appflowy/mobile/presentation/database/card/card.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_style_maps/mobile_board_card_cell_style.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileBoardPage extends StatefulWidget {
  const MobileBoardPage({
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
  State<MobileBoardPage> createState() => _MobileBoardPageState();
}

class _MobileBoardPageState extends State<MobileBoardPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<BoardBloc>(
      create: (_) => BoardBloc(
        databaseController: widget.databaseController,
      )..add(const BoardEvent.initial()),
      child: BlocBuilder<BoardBloc, BoardState>(
        buildWhen: (p, c) => !p.isReady && c.isReady,
        builder: (context, state) => state.maybeMap(
          loading: (_) => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
          error: (err) => FlowyMobileStateContainer.error(
            emoji: '🛸',
            title: LocaleKeys.board_mobile_failedToLoad.tr(),
            errorMsg: err.toString(),
          ),
          ready: (data) => const _BoardContent(),
          orElse: () => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _BoardContent extends StatefulWidget {
  const _BoardContent();

  @override
  State<_BoardContent> createState() => _BoardContentState();
}

class _BoardContentState extends State<_BoardContent> {
  late final ScrollController scrollController;
  late final AppFlowyBoardScrollController scrollManager;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final config = AppFlowyBoardConfig(
      groupCornerRadius: 8,
      groupBackgroundColor: Theme.of(context).colorScheme.secondary,
      groupMargin: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      groupHeaderPadding: const EdgeInsets.all(8),
      groupBodyPadding: const EdgeInsets.all(4),
      groupFooterPadding: const EdgeInsets.all(8),
      cardMargin: const EdgeInsets.all(4),
    );

    return BlocListener<BoardBloc, BoardState>(
      listener: (context, state) {
        state.maybeMap(
          orElse: () {},
          ready: (value) {
            if (context.mounted && value.createdRow != null) {
              context.push(
                MobileRowDetailPage.routeName,
                extra: {
                  MobileRowDetailPage.argRowId: value.createdRow!.rowMeta.id,
                  MobileRowDetailPage.argDatabaseController:
                      context.read<BoardBloc>().databaseController,
                },
              );
            }
          },
        );
      },
      child: BlocBuilder<BoardBloc, BoardState>(
        builder: (context, state) {
          return state.maybeMap(
            orElse: () => const SizedBox.shrink(),
            ready: (state) {
              final showCreateGroupButton = context
                      .read<BoardBloc>()
                      .groupingFieldType
                      ?.canCreateNewGroup ??
                  false;
              final showHiddenGroups = state.hiddenGroups.isNotEmpty;
              return AppFlowyBoard(
                boardScrollController: scrollManager,
                scrollController: scrollController,
                controller: context.read<BoardBloc>().boardController,
                groupConstraints:
                    BoxConstraints.tightFor(width: screenWidth * 0.7),
                config: config,
                leading: showHiddenGroups
                    ? MobileHiddenGroupsColumn(
                        padding: config.groupHeaderPadding,
                      )
                    : const HSpace(16),
                trailing: showCreateGroupButton
                    ? const MobileBoardTrailing()
                    : const HSpace(16),
                headerBuilder: (_, groupData) => BlocProvider<BoardBloc>.value(
                  value: context.read<BoardBloc>(),
                  child: GroupCardHeader(
                    groupData: groupData,
                  ),
                ),
                footerBuilder: _buildFooter,
                cardBuilder: (_, column, columnItem) => _buildCard(
                  context: context,
                  afGroupData: column,
                  afGroupItem: columnItem,
                  cardMargin: config.cardMargin,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppFlowyGroupData columnData) {
    final style = Theme.of(context);

    return SizedBox(
      height: 42,
      width: double.infinity,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.only(left: 8),
          alignment: Alignment.centerLeft,
        ),
        icon: FlowySvg(
          FlowySvgs.add_m,
          color: style.colorScheme.onSurface,
        ),
        label: Text(
          LocaleKeys.board_column_createNewCard.tr(),
          style: style.textTheme.bodyMedium?.copyWith(
            color: style.colorScheme.onSurface,
          ),
        ),
        onPressed: () => context.read<BoardBloc>().add(
              BoardEvent.createRow(
                columnData.id,
                OrderObjectPositionTypePB.End,
                null,
                null,
              ),
            ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required AppFlowyGroupData afGroupData,
    required AppFlowyGroupItem afGroupItem,
    required EdgeInsets cardMargin,
  }) {
    final boardBloc = context.read<BoardBloc>();
    final groupItem = afGroupItem as GroupItem;
    final groupData = afGroupData.customData as GroupData;
    final rowMeta = groupItem.row;

    final cellBuilder =
        CardCellBuilder(databaseController: boardBloc.databaseController);

    final groupItemId = groupItem.row.id + groupData.group.groupId;

    return Container(
      key: ValueKey(groupItemId),
      margin: cardMargin,
      decoration: _makeBoxDecoration(context),
      child: RowCard(
        fieldController: boardBloc.fieldController,
        rowMeta: rowMeta,
        viewId: boardBloc.viewId,
        rowCache: boardBloc.rowCache,
        groupingFieldId: groupItem.fieldInfo.id,
        isEditing: false,
        cellBuilder: cellBuilder,
        onTap: (context) {
          context.push(
            MobileRowDetailPage.routeName,
            extra: {
              MobileRowDetailPage.argRowId: rowMeta.id,
              MobileRowDetailPage.argDatabaseController:
                  context.read<BoardBloc>().databaseController,
            },
          );
        },
        onStartEditing: () {},
        onEndEditing: () {},
        styleConfiguration: RowCardStyleConfiguration(
          cellStyleMap: mobileBoardCardCellStyleMap(context),
          showAccessory: false,
        ),
      ),
    );
  }

  BoxDecoration _makeBoxDecoration(BuildContext context) {
    final themeMode = context.read<AppearanceSettingsCubit>().state.themeMode;
    return BoxDecoration(
      color: Theme.of(context).colorScheme.background,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      border: themeMode == ThemeMode.light
          ? Border.fromBorderSide(
              BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
            )
          : null,
      boxShadow: themeMode == ThemeMode.light
          ? [
              BoxShadow(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }
}
