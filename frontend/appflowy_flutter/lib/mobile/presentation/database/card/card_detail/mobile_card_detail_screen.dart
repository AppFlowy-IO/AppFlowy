import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/row_page_button.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_quick_action_button.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/text_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_banner_bloc.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/grid/application/row/mobile_row_detail_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/text.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/row_property.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
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
        appBar: FlowyAppBar(
          leadingType: FlowyAppBarLeadingType.close,
          showDivider: false,
          actions: [
            AppBarMoreButton(
              onTap: (_) => _showCardActions(context),
            ),
          ],
        ),
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

  void _showCardActions(BuildContext context) {
    showMobileBottomSheet(
      context,
      backgroundColor: AFThemeExtension.of(context).background,
      showDragHandle: true,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MobileQuickActionButton(
            onTap: () =>
                _performAction(viewId, _bloc.state.currentRowId, false),
            icon: FlowySvgs.duplicate_s,
            text: LocaleKeys.button_duplicate.tr(),
          ),
          const Divider(height: 8.5, thickness: 0.5),
          MobileQuickActionButton(
            onTap: () => _performAction(viewId, _bloc.state.currentRowId, true),
            text: LocaleKeys.button_delete.tr(),
            textColor: Theme.of(context).colorScheme.error,
            icon: FlowySvgs.trash_s,
            iconColor: Theme.of(context).colorScheme.error,
          ),
          const Divider(height: 8.5, thickness: 0.5),
        ],
      ),
    );
  }

  void _performAction(String viewId, String? rowId, bool deleteRow) {
    if (rowId == null) {
      return;
    }

    deleteRow
        ? RowBackendService.deleteRows(viewId, [rowId])
        : RowBackendService.duplicateRow(viewId, rowId);

    context
      ..pop()
      ..pop();
    Fluttertoast.showToast(
      msg: deleteRow
          ? LocaleKeys.board_cardDeleted.tr()
          : LocaleKeys.board_cardDuplicated.tr(),
      gravity: ToastGravity.BOTTOM,
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
                    child: previousDisabled
                        ? Icon(
                            Icons.chevron_left_outlined,
                            color: Theme.of(context).disabledColor,
                          )
                        : InkWell(
                            borderRadius: BorderRadius.circular(26),
                            onTap: onTapPrevious,
                            child: const Icon(Icons.chevron_left_outlined),
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
                    child: nextDisabled
                        ? Icon(
                            Icons.chevron_right_outlined,
                            color: Theme.of(context).disabledColor,
                          )
                        : InkWell(
                            borderRadius: BorderRadius.circular(26),
                            onTap: onTapNext,
                            child: const Icon(Icons.chevron_right_outlined),
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
  late final EditableCellBuilder cellBuilder;

  String get viewId => widget.databaseController.viewId;
  RowCache get rowCache => widget.databaseController.rowCache;
  FieldController get fieldController =>
      widget.databaseController.fieldController;
  ValueNotifier<String> primaryFieldId = ValueNotifier('');

  @override
  void initState() {
    super.initState();

    rowController = RowController(
      rowMeta: widget.rowMeta,
      viewId: viewId,
      rowCache: rowCache,
    );
    rowController.initialize();

    cellBuilder = EditableCellBuilder(
      databaseController: widget.databaseController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RowDetailBloc>(
      create: (_) => RowDetailBloc(
        fieldController: fieldController,
        rowController: rowController,
      ),
      child: BlocBuilder<RowDetailBloc, RowDetailState>(
        builder: (context, rowDetailState) {
          return Column(
            children: [
              BlocProvider<RowBannerBloc>(
                create: (context) => RowBannerBloc(
                  viewId: viewId,
                  fieldController: fieldController,
                  rowMeta: rowController.rowMeta,
                )..add(const RowBannerEvent.initial()),
                child: BlocConsumer<RowBannerBloc, RowBannerState>(
                  listener: (context, state) {
                    if (state.primaryField == null) {
                      return;
                    }
                    primaryFieldId.value = state.primaryField!.id;
                  },
                  builder: (context, state) {
                    if (state.primaryField == null) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: cellBuilder.buildCustom(
                        CellContext(
                          rowId: rowController.rowId,
                          fieldId: state.primaryField!.id,
                        ),
                        skinMap: EditableCellSkinMap(
                          textSkin: _TitleSkin(),
                        ),
                      ),
                    );
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
                        databaseController: widget.databaseController,
                        cellBuilder: cellBuilder,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (rowDetailState.numHiddenFields != 0) ...[
                            const ToggleHiddenFieldsVisibilityButton(),
                          ],
                          const VSpace(8.0),
                          ValueListenableBuilder(
                            valueListenable: primaryFieldId,
                            builder: (context, primaryFieldId, child) {
                              if (primaryFieldId.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return OpenRowPageButton(
                                databaseController: widget.databaseController,
                                cellContext: CellContext(
                                  rowId: rowController.rowId,
                                  fieldId: primaryFieldId,
                                ),
                                documentId: rowController.rowMeta.documentId,
                              );
                            },
                          ),
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

class _TitleSkin extends IEditableTextCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TextCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
  ) {
    return TextField(
      controller: textEditingController,
      focusNode: focusNode,
      maxLines: null,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 23,
            fontWeight: FontWeight.w500,
          ),
      onChanged: (text) => bloc.add(TextCellEvent.updateText(text)),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 9),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        hintText: LocaleKeys.grid_row_titlePlaceholder.tr(),
        isDense: true,
        isCollapsed: true,
      ),
      onTapOutside: (event) => focusNode.unfocus(),
    );
  }
}
