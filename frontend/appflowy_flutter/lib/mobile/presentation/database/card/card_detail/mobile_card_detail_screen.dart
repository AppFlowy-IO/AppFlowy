import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_action_widget.dart';
import 'package:appflowy/mobile/presentation/widgets/show_flowy_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/row/row_banner_bloc.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_action_sheet_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/cells.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/mobile_row_property_list.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_document.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

class MobileCardDetailScreen extends StatefulWidget {
  const MobileCardDetailScreen({
    super.key,
    required this.rowController,
    required this.cellBuilder,
  });

  static const routeName = '/MobileCardDetailScreen';
  static const argRowController = 'rowController';
  static const argCellBuilder = 'cellBuilder';
  final RowController rowController;
  final GridCellBuilder cellBuilder;

  @override
  State<MobileCardDetailScreen> createState() => _MobileCardDetailScreenState();
}

class _MobileCardDetailScreenState extends State<MobileCardDetailScreen> {
  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO(yijing): fix context issue when navigating in bottom navigation bar
    return BlocProvider(
      create: (context) => RowDetailBloc(rowController: widget.rowController)
        ..add(const RowDetailEvent.initial()),
      child: Scaffold(
        // appbar with duplicate and delete card features
        appBar: AppBar(
          title: Text(LocaleKeys.board_cardDetail.tr()),
          actions: [
            BlocProvider<RowActionSheetBloc>(
              create: (context) => RowActionSheetBloc(
                viewId: widget.rowController.viewId,
                rowId: widget.rowController.rowId,
                groupId: widget.rowController.groupId,
              ),
              child: Builder(
                builder: (context) {
                  return IconButton(
                    onPressed: () {
                      showFlowyMobileBottomSheet(
                        context,
                        title: LocaleKeys.board_cardActions.tr(),
                        builder: (_) => Row(
                          children: [
                            Expanded(
                              child: BottomSheetActionWidget(
                                svg: FlowySvgs.copy_s,
                                text: LocaleKeys.button_duplicate.tr(),
                                onTap: () {
                                  context.read<RowActionSheetBloc>().add(
                                        const RowActionSheetEvent
                                            .duplicateRow(),
                                      );
                                  context
                                    ..pop()
                                    ..pop();
                                  Fluttertoast.showToast(
                                    msg: LocaleKeys.board_cardDuplicated.tr(),
                                    gravity: ToastGravity.CENTER,
                                  );
                                },
                              ),
                            ),
                            const HSpace(8),
                            Expanded(
                              child: BottomSheetActionWidget(
                                svg: FlowySvgs.m_delete_m,
                                text: LocaleKeys.button_delete.tr(),
                                onTap: () {
                                  context.read<RowActionSheetBloc>().add(
                                        const RowActionSheetEvent.deleteRow(),
                                      );
                                  context
                                    ..pop()
                                    ..pop();
                                  Fluttertoast.showToast(
                                    msg: LocaleKeys.board_cardDeleted.tr(),
                                    gravity: ToastGravity.CENTER,
                                  );
                                },
                              ),
                            )
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.more_horiz),
                  );
                },
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              BlocProvider<RowBannerBloc>(
                create: (context) => RowBannerBloc(
                  viewId: widget.rowController.viewId,
                  rowMeta: widget.rowController.rowMeta,
                )..add(const RowBannerEvent.initial()),
                child: BlocBuilder<RowBannerBloc, RowBannerState>(
                  builder: (context, state) {
                    // primaryField is the property cannot be deleted like card title
                    if (state.primaryField != null) {
                      final mobileStyle = GridTextCellStyle(
                        placeholder: LocaleKeys.grid_row_titlePlaceholder.tr(),
                        textStyle: Theme.of(context).textTheme.titleLarge,
                      );

                      // get the cell context for the card title
                      final cellContext = DatabaseCellContext(
                        viewId: widget.rowController.viewId,
                        rowMeta: widget.rowController.rowMeta,
                        fieldInfo: FieldInfo.initial(state.primaryField!),
                      );

                      return widget.cellBuilder.build(
                        cellContext,
                        style: mobileStyle,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const VSpace(8),
              // Card Properties
              MobileRowPropertyList(
                cellBuilder: widget.cellBuilder,
                viewId: widget.rowController.viewId,
              ),
              const Divider(),
              const VSpace(16),
              RowDocument(
                viewId: widget.rowController.viewId,
                rowId: widget.rowController.rowId,
                scrollController: scrollController,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
