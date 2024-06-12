import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/translate_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/translate_row_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/cell/desktop_grid/desktop_grid_translate_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell/desktop_row_detail/destop_row_detail_translate_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell/mobile_grid/mobile_grid_translate_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell/mobile_row_detail/mobile_row_detail_translate_cell.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class IEditableTranslateCellSkin {
  const IEditableTranslateCellSkin();

  factory IEditableTranslateCellSkin.fromStyle(EditableCellStyle style) {
    return switch (style) {
      EditableCellStyle.desktopGrid => DesktopGridTranslateCellSkin(),
      EditableCellStyle.desktopRowDetail => DesktopRowDetailTranslateCellSkin(),
      EditableCellStyle.mobileGrid => MobileGridTranslateCellSkin(),
      EditableCellStyle.mobileRowDetail => MobileRowDetailTranslateCellSkin(),
    };
  }

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TranslateCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
  );
}

class EditableTranslateCell extends EditableCellWidget {
  EditableTranslateCell({
    super.key,
    required this.databaseController,
    required this.cellContext,
    required this.skin,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;
  final IEditableTranslateCellSkin skin;

  @override
  GridEditableTextCell<EditableTranslateCell> createState() =>
      _TranslateCellState();
}

class _TranslateCellState extends GridEditableTextCell<EditableTranslateCell> {
  late final TextEditingController _textEditingController;
  late final cellBloc = TranslateCellBloc(
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
      child: BlocListener<TranslateCellBloc, TranslateCellState>(
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
      cellBloc.add(
        TranslateCellEvent.updateCell(_textEditingController.text.trim()),
      );
    }
    return super.focusChanged();
  }
}

class TranslateCellAccessory extends StatelessWidget {
  const TranslateCellAccessory({
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
      create: (context) => TranslateRowBloc(
        viewId: viewId,
        rowId: rowId,
        fieldId: fieldId,
      ),
      child: BlocBuilder<TranslateRowBloc, TranslateRowState>(
        builder: (context, state) {
          return const Row(
            children: [TranslateButton(), HSpace(6), CopyButton()],
          );
        },
      ),
    );
  }
}

class TranslateButton extends StatelessWidget {
  const TranslateButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TranslateRowBloc, TranslateRowState>(
      builder: (context, state) {
        return state.loadingState.map(
          loading: (_) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          },
          finish: (_) {
            return FlowyTooltip(
              message: LocaleKeys.tooltip_aiGenerate.tr(),
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
                        .read<TranslateRowBloc>()
                        .add(const TranslateRowEvent.startTranslate());
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
    return BlocBuilder<TranslateCellBloc, TranslateCellState>(
      builder: (blocContext, state) {
        return FlowyTooltip(
          message: LocaleKeys.settings_menu_clickToCopy.tr(),
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
              onPressed: () {
                Clipboard.setData(ClipboardData(text: state.content));
                showMessageToast(LocaleKeys.grid_row_copyProperty.tr());
              },
            ),
          ),
        );
      },
    );
  }
}
