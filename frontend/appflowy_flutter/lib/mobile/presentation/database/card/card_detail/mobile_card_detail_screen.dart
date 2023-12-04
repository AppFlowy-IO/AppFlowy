import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/row/row_banner_bloc.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/mobile_row_detail_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/cells.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_property.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

import 'widgets/mobile_create_field_button.dart';
import 'widgets/mobile_row_property_list.dart';

class MobileRowDetailPage extends StatefulWidget {
  const MobileRowDetailPage({
    super.key,
    required this.databaseController,
    required this.rowId,
  });

  static const routeName = '/MobileRowDetailPage';
  static const argDatabaseController = 'databaseController';
  static const argRowId = 'rowId';

  final DatabaseController databaseController;
  final String rowId;

  @override
  State<MobileRowDetailPage> createState() => _MobileRowDetailPageState();
}

class _MobileRowDetailPageState extends State<MobileRowDetailPage> {
  late final MobileRowDetailBloc _bloc;
  late final PageController _pageController;

  String get viewId => widget.databaseController.viewId;
  RowCache get rowCache => widget.databaseController.rowCache;
  FieldController get fieldController =>
      widget.databaseController.fieldController;

  @override
  void initState() {
    super.initState();
    _bloc = MobileRowDetailBloc(
      databaseController: widget.databaseController,
    )..add(MobileRowDetailEvent.initial(widget.rowId));
    final initialPage = rowCache.rowInfos
        .indexWhere((rowInfo) => rowInfo.rowId == widget.rowId);
    _pageController =
        PageController(initialPage: initialPage == -1 ? 0 : initialPage);
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: BlocBuilder<MobileRowDetailBloc, MobileRowDetailState>(
          buildWhen: (previous, current) =>
              previous.rowInfos.length != current.rowInfos.length,
          builder: (context, state) {
            if (state.isLoading) {
              return const SizedBox.shrink();
            }
            return PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                final rowId = _bloc.state.rowInfos[page].rowId;
                _bloc.add(MobileRowDetailEvent.changeRowId(rowId));
              },
              itemCount: state.rowInfos.length,
              itemBuilder: (context, index) {
                if (state.rowInfos.isEmpty || state.currentRowId == null) {
                  return const SizedBox.shrink();
                }
                return MobileRowDetailPageContent(
                  databaseController: widget.databaseController,
                  rowMeta: state.rowInfos[index].rowMeta,
                );
              },
            );
          },
        ),
        floatingActionButton: RowDetailFab(
          onTapPrevious: () => _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          ),
          onTapNext: () => _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.close),
      ),
      actions: [
        IconButton(
          iconSize: 40,
          icon: const FlowySvg(
            FlowySvgs.details_horizontal_s,
            size: Size.square(20),
          ),
          padding: EdgeInsets.zero,
          onPressed: () => _showCardActions(context),
        ),
      ],
    );
  }

  void _showCardActions(BuildContext context) {
    showMobileBottomSheet(
      context,
      backgroundColor: Theme.of(context).colorScheme.background,
      padding: const EdgeInsets.only(top: 4, bottom: 32),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _CardActionButton(
              onTap: () {
                final rowId = _bloc.state.currentRowId;
                if (rowId == null) {
                  return;
                }
                RowBackendService.duplicateRow(viewId, rowId);
                context
                  ..pop()
                  ..pop();
                Fluttertoast.showToast(
                  msg: LocaleKeys.board_cardDuplicated.tr(),
                  gravity: ToastGravity.BOTTOM,
                );
              },
              icon: FlowySvgs.copy_s,
              text: LocaleKeys.button_duplicate.tr(),
            ),
          ),
          const Divider(height: 9),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _CardActionButton(
              onTap: () {
                final rowId = _bloc.state.currentRowId;
                if (rowId == null) {
                  return;
                }
                RowBackendService.deleteRow(viewId, rowId);
                context
                  ..pop()
                  ..pop();
                Fluttertoast.showToast(
                  msg: LocaleKeys.board_cardDeleted.tr(),
                  gravity: ToastGravity.BOTTOM,
                );
              },
              icon: FlowySvgs.m_delete_m,
              text: LocaleKeys.button_delete.tr(),
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const Divider(height: 9),
        ],
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.onTap,
    required this.icon,
    required this.text,
    this.color,
  });

  final VoidCallback onTap;
  final FlowySvgData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            FlowySvg(icon, size: const Size.square(20), color: color),
            const HSpace(8),
            FlowyText(text, fontSize: 15, color: color),
          ],
        ),
      ),
    );
  }
}

class RowDetailFab extends StatelessWidget {
  const RowDetailFab({
    super.key,
    required this.onTapPrevious,
    required this.onTapNext,
  });

  final VoidCallback onTapPrevious;
  final VoidCallback onTapNext;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MobileRowDetailBloc, MobileRowDetailState>(
      builder: (context, state) {
        final rowCount = state.rowInfos.length;
        final rowIndex = state.rowInfos.indexWhere(
          (rowInfo) => rowInfo.rowId == state.currentRowId,
        );
        if (rowIndex == -1 || rowCount == 0) {
          return const SizedBox.shrink();
        }

        final previousDisabled = rowIndex == 0;
        final nextDisabled = rowIndex == rowCount - 1;

        return IntrinsicWidth(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  offset: Offset(0, 8),
                  blurRadius: 20,
                  spreadRadius: 0,
                  color: Color(0x191F2329),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: 48,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(26),
                    borderOnForeground: false,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: () {
                        if (!previousDisabled) {
                          onTapPrevious();
                        }
                      },
                      child: Icon(
                        Icons.chevron_left_outlined,
                        color: previousDisabled
                            ? Theme.of(context).disabledColor
                            : null,
                      ),
                    ),
                  ),
                ),
                FlowyText.medium(
                  "${rowIndex + 1} / $rowCount",
                  fontSize: 14,
                ),
                SizedBox.square(
                  dimension: 48,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(26),
                    borderOnForeground: false,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: () {
                        if (!nextDisabled) {
                          onTapNext();
                        }
                      },
                      child: Icon(
                        Icons.chevron_right_outlined,
                        color: nextDisabled
                            ? Theme.of(context).disabledColor
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MobileRowDetailPageContent extends StatefulWidget {
  const MobileRowDetailPageContent({
    super.key,
    required this.databaseController,
    required this.rowMeta,
  });

  final DatabaseController databaseController;
  final RowMetaPB rowMeta;

  @override
  State<MobileRowDetailPageContent> createState() =>
      MobileRowDetailPageContentState();
}

class MobileRowDetailPageContentState
    extends State<MobileRowDetailPageContent> {
  late final RowController rowController;
  late final MobileRowDetailPageCellBuilder cellBuilder;

  String get viewId => widget.databaseController.viewId;
  RowCache get rowCache => widget.databaseController.rowCache;
  FieldController get fieldController =>
      widget.databaseController.fieldController;

  @override
  void initState() {
    super.initState();

    rowController = RowController(
      rowMeta: widget.rowMeta,
      viewId: viewId,
      rowCache: rowCache,
    );
    cellBuilder = MobileRowDetailPageCellBuilder(
      cellCache: rowCache.cellCache,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RowDetailBloc>(
      create: (_) => RowDetailBloc(rowController: rowController)
        ..add(const RowDetailEvent.initial()),
      child: BlocBuilder<RowDetailBloc, RowDetailState>(
        builder: (context, rowDetailState) {
          return Column(
            children: [
              BlocProvider<RowBannerBloc>(
                create: (context) => RowBannerBloc(
                  viewId: viewId,
                  rowMeta: rowController.rowMeta,
                )..add(const RowBannerEvent.initial()),
                child: BlocBuilder<RowBannerBloc, RowBannerState>(
                  builder: (context, state) {
                    if (state.primaryField != null) {
                      final cellStyle = GridTextCellStyle(
                        placeholder: LocaleKeys.grid_row_titlePlaceholder.tr(),
                        textStyle:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w500,
                                ),
                        cellPadding: const EdgeInsets.symmetric(vertical: 9),
                        useRoundedBorder: false,
                      );

                      final cellContext = DatabaseCellContext(
                        viewId: viewId,
                        rowMeta: rowController.rowMeta,
                        fieldInfo: FieldInfo.initial(state.primaryField!),
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: cellBuilder.build(
                          cellContext,
                          style: cellStyle,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 9, bottom: 100),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: MobileRowPropertyList(
                        cellBuilder: cellBuilder,
                        viewId: viewId,
                        fieldController: fieldController,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (rowDetailState.numHiddenFields != 0) ...[
                            const ToggleHiddenFieldsVisibilityButton(),
                            const VSpace(12),
                          ],
                          MobileRowDetailCreateFieldButton(
                            viewId: viewId,
                            fieldController: fieldController,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
