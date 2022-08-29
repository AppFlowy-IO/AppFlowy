// ignore_for_file: unused_field

import 'dart:collection';

import 'package:app_flowy/plugins/board/application/card/card_data_controller.dart';
import 'package:app_flowy/plugins/grid/application/row/row_cache.dart';
import 'package:app_flowy/plugins/grid/application/field/field_cache.dart';
import 'package:app_flowy/plugins/grid/application/row/row_data_controller.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/cell_builder.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/row/row_detail.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../grid/application/row/row_cache.dart';
import '../application/board_bloc.dart';
import 'card/card.dart';
import 'card/card_cell_builder.dart';

class BoardPage extends StatelessWidget {
  final ViewPB view;
  BoardPage({required this.view, Key? key}) : super(key: ValueKey(view.id));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          BoardBloc(view: view)..add(const BoardEvent.initial()),
      child: BlocBuilder<BoardBloc, BoardState>(
        buildWhen: (previous, current) =>
            previous.loadingState != current.loadingState,
        builder: (context, state) {
          return state.loadingState.map(
            loading: (_) =>
                const Center(child: CircularProgressIndicator.adaptive()),
            finish: (result) {
              return result.successOrFail.fold(
                (_) => const BoardContent(),
                (err) => FlowyErrorPage(err.toString()),
              );
            },
          );
        },
      ),
    );
  }
}

class BoardContent extends StatefulWidget {
  const BoardContent({Key? key}) : super(key: key);

  @override
  State<BoardContent> createState() => _BoardContentState();
}

class _BoardContentState extends State<BoardContent> {
  late ScrollController scrollController;
  late AFBoardScrollManager scrollManager;

  final config = AFBoardConfig(
    columnBackgroundColor: HexColor.fromHex('#F7F8FC'),
  );

  @override
  void initState() {
    scrollController = ScrollController();
    scrollManager = AFBoardScrollManager();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BoardBloc, BoardState>(
      listener: (context, state) {
        state.editingRow.fold(
          () => null,
          (editingRow) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              scrollManager.scrollToBottom(editingRow.columnId, () {
                context
                    .read<BoardBloc>()
                    .add(BoardEvent.endEditRow(editingRow.row.id));
              });
            });
          },
        );
      },
      child: BlocBuilder<BoardBloc, BoardState>(
        buildWhen: (previous, current) =>
            previous.groupIds.length != current.groupIds.length,
        builder: (context, state) {
          return Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: AFBoard(
                scrollManager: scrollManager,
                scrollController: scrollController,
                dataController: context.read<BoardBloc>().boardController,
                headerBuilder: _buildHeader,
                footBuilder: _buildFooter,
                cardBuilder: (_, column, columnItem) => _buildCard(
                  context,
                  column,
                  columnItem,
                ),
                columnConstraints: const BoxConstraints.tightFor(width: 240),
                config: AFBoardConfig(
                  columnBackgroundColor: HexColor.fromHex('#F7F8FC'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Widget _buildHeader(
      BuildContext context, AFBoardColumnHeaderData headerData) {
    return AppFlowyColumnHeader(
      title: Flexible(
        fit: FlexFit.tight,
        child: FlowyText.medium(
          headerData.columnName,
          fontSize: 14,
          overflow: TextOverflow.clip,
          color: context.read<AppTheme>().textColor,
        ),
      ),
      // addIcon: const Icon(Icons.add, size: 20),
      // moreIcon: SizedBox(
      //   width: 20,
      //   height: 20,
      //   child: svgWidget(
      //     'grid/details',
      //     color: context.read<AppTheme>().iconColor,
      //   ),
      // ),
      height: 50,
      margin: config.headerPadding,
    );
  }

  Widget _buildFooter(BuildContext context, AFBoardColumnData columnData) {
    return AppFlowyColumnFooter(
        icon: SizedBox(
          height: 20,
          width: 20,
          child: svgWidget(
            "home/add",
            color: context.read<AppTheme>().iconColor,
          ),
        ),
        title: FlowyText.medium(
          "New",
          fontSize: 14,
          color: context.read<AppTheme>().textColor,
        ),
        height: 50,
        margin: config.footerPadding,
        onAddButtonClick: () {
          context.read<BoardBloc>().add(BoardEvent.createRow(columnData.id));
        });
  }

  Widget _buildCard(
    BuildContext context,
    AFBoardColumnData column,
    AFColumnItem columnItem,
  ) {
    final boardColumnItem = columnItem as BoardColumnItem;
    final rowPB = boardColumnItem.row;
    final rowCache = context.read<BoardBloc>().getRowCache(rowPB.blockId);

    /// Return placeholder widget if the rowCache is null.
    if (rowCache == null) return SizedBox(key: ObjectKey(columnItem));

    final fieldCache = context.read<BoardBloc>().fieldCache;
    final gridId = context.read<BoardBloc>().gridId;
    final cardController = CardDataController(
      fieldCache: fieldCache,
      rowCache: rowCache,
      rowPB: rowPB,
    );

    final cellBuilder = BoardCellBuilder(cardController);

    final isEditing = context.read<BoardBloc>().state.editingRow.isSome();

    return AppFlowyColumnItemCard(
      key: ValueKey(columnItem.id),
      margin: config.cardPadding,
      decoration: _makeBoxDecoration(context),
      child: BoardCard(
        gridId: gridId,
        groupId: column.id,
        fieldId: boardColumnItem.fieldId,
        isEditing: isEditing,
        cellBuilder: cellBuilder,
        dataController: cardController,
        openCard: (context) => _openCard(
          gridId,
          fieldCache,
          rowPB,
          rowCache,
          context,
        ),
      ),
    );
  }

  BoxDecoration _makeBoxDecoration(BuildContext context) {
    final theme = context.read<AppTheme>();
    final borderSide = BorderSide(color: theme.shader6, width: 1.0);
    return BoxDecoration(
      color: theme.surface,
      border: Border.fromBorderSide(borderSide),
      borderRadius: const BorderRadius.all(Radius.circular(6)),
    );
  }

  void _openCard(String gridId, GridFieldCache fieldCache, RowPB rowPB,
      GridRowCache rowCache, BuildContext context) {
    final rowInfo = RowInfo(
      gridId: gridId,
      fields: UnmodifiableListView(fieldCache.fields),
      rowPB: rowPB,
    );

    final dataController = GridRowDataController(
      rowInfo: rowInfo,
      fieldCache: fieldCache,
      rowCache: rowCache,
    );

    RowDetailPage(
      cellBuilder: GridCellBuilder(delegate: dataController),
      dataController: dataController,
    ).show(context);
  }
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
