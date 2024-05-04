import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/summary_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/summary_row_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/cell/desktop_grid/desktop_grid_summary_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell/desktop_row_detail/desktop_row_detail_summary_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell/mobile_grid/mobile_grid_summary_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell/mobile_row_detail/mobile_row_detail_summary_cell.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class IEditableSummaryCellSkin {
  const IEditableSummaryCellSkin();

  factory IEditableSummaryCellSkin.fromStyle(EditableCellStyle style) {
    return switch (style) {
      EditableCellStyle.desktopGrid => DesktopGridSummaryCellSkin(),
      EditableCellStyle.desktopRowDetail => DesktopRowDetailSummaryCellSkin(),
      EditableCellStyle.mobileGrid => MobileGridSummaryCellSkin(),
      EditableCellStyle.mobileRowDetail => MobileRowDetailSummaryCellSkin(),
    };
  }

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    SummaryCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
  );
}

class EditableSummaryCell extends EditableCellWidget {
  EditableSummaryCell({
    super.key,
    required this.databaseController,
    required this.cellContext,
    required this.skin,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;
  final IEditableSummaryCellSkin skin;

  @override
  GridEditableTextCell<EditableSummaryCell> createState() =>
      _SummaryCellState();
}

class _SummaryCellState extends GridEditableTextCell<EditableSummaryCell> {
  late final TextEditingController _textEditingController;
  late final cellBloc = SummaryCellBloc(
    cellController: makeCellController(
      widget.databaseController,
      widget.cellContext,
    ).as(),
  );

  @override
  void initState() {
    super.initState();
    _textEditingController =
        TextEditingController(text: cellBloc.state.content);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cellBloc,
      child: BlocListener<SummaryCellBloc, SummaryCellState>(
        listener: (context, state) {
          _textEditingController.text = state.content;
        },
        child: Builder(
          builder: (context) {
            return widget.skin.build(
              context,
              widget.cellContainerNotifier,
              cellBloc,
              focusNode,
              _textEditingController,
            );
          },
        ),
      ),
    );
  }

  @override
  SingleListenerFocusNode focusNode = SingleListenerFocusNode();

  @override
  void onRequestFocus() {
    focusNode.requestFocus();
  }

  @override
  String? onCopy() => cellBloc.state.content;

  @override
  Future<void> focusChanged() {
    if (mounted &&
        !cellBloc.isClosed &&
        cellBloc.state.content != _textEditingController.text.trim()) {
      cellBloc
          .add(SummaryCellEvent.updateCell(_textEditingController.text.trim()));
    }
    return super.focusChanged();
  }
}

class SummaryCellAccessory extends StatelessWidget {
  const SummaryCellAccessory({
    required this.viewId,
    required this.rowId,
    required this.fieldId,
    super.key,
  });

  final String viewId;
  final String rowId;
  final String fieldId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SummaryRowBloc(
        viewId: viewId,
        rowId: rowId,
        fieldId: fieldId,
      ),
      child: BlocBuilder<SummaryRowBloc, SummaryRowState>(
        builder: (context, state) {
          return const Row(
            children: [SummaryButton(), HSpace(6), CopyButton()],
          );
        },
      ),
    );
  }
}

class SummaryButton extends StatelessWidget {
  const SummaryButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SummaryRowBloc, SummaryRowState>(
      builder: (context, state) {
        return state.loadingState.map(
          loading: (_) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          },
          finish: (_) {
            return FlowyTooltip(
              message: LocaleKeys.tooltip_genSummary.tr(),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  border: Border.fromBorderSide(
                    BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  borderRadius: Corners.s6Border,
                ),
                child: FlowyIconButton(
                  hoverColor: AFThemeExtension.of(context).lightGreyHover,
                  fillColor: Theme.of(context).cardColor,
                  icon: FlowySvg(
                    FlowySvgs.ai_summary_generate_s,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    context
                        .read<SummaryRowBloc>()
                        .add(const SummaryRowEvent.startSummary());
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class CopyButton extends StatelessWidget {
  const CopyButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.tooltip_genSummary.tr(),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          border: Border.fromBorderSide(
            BorderSide(color: Theme.of(context).dividerColor),
          ),
          borderRadius: Corners.s6Border,
        ),
        child: FlowyIconButton(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          fillColor: Theme.of(context).cardColor,
          icon: FlowySvg(
            FlowySvgs.ai_copy_s,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {},
        ),
      ),
    );
  }
}
