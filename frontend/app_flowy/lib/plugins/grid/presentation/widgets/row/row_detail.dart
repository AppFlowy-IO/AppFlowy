import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:app_flowy/plugins/grid/application/row/row_data_controller.dart';
import 'package:app_flowy/plugins/grid/application/row/row_detail_bloc.dart';
import 'package:app_flowy/workspace/presentation/widgets/dialogs.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

import '../../layout/sizes.dart';
import '../cell/cell_accessory.dart';
import '../cell/prelude.dart';
import '../header/field_cell.dart';
import '../header/field_editor.dart';

class RowDetailPage extends StatefulWidget with FlowyOverlayDelegate {
  final RowDataController dataController;
  final GridCellBuilder cellBuilder;

  const RowDetailPage({
    required this.dataController,
    required this.cellBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<RowDetailPage> createState() => _RowDetailPageState();

  static String identifier() {
    return (RowDetailPage).toString();
  }
}

class _RowDetailPageState extends State<RowDetailPage> {
  @override
  Widget build(BuildContext context) {
    return FlowyDialog(
      child: BlocProvider(
        create: (context) {
          final bloc = RowDetailBloc(
            dataController: widget.dataController,
          );
          bloc.add(const RowDetailEvent.initial());
          return bloc;
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Column(
            children: [
              SizedBox(
                height: 30,
                child: Row(
                  children: const [Spacer(), _CloseButton()],
                ),
              ),
              Expanded(
                child: _PropertyList(
                  cellBuilder: widget.cellBuilder,
                  viewId: widget.dataController.rowInfo.gridId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: 24,
      onPressed: () {
        FlowyOverlay.pop(context);
      },
      iconPadding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
      icon: svgWidget(
        "home/close",
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _PropertyList extends StatelessWidget {
  final String viewId;
  final GridCellBuilder cellBuilder;
  final ScrollController _scrollController;
  _PropertyList({
    required this.viewId,
    required this.cellBuilder,
    Key? key,
  })  : _scrollController = ScrollController(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowDetailBloc, RowDetailState>(
      buildWhen: (previous, current) => previous.gridCells != current.gridCells,
      builder: (context, state) {
        return Column(
          children: [
            Expanded(child: _wrapScrollbar(buildRowCells(state))),
            const VSpace(10),
            _CreateFieldButton(
              viewId: viewId,
              onClosed: _handleDidCreateField,
            ),
          ],
        );
      },
    );
  }

  Widget buildRowCells(RowDetailState state) {
    return ListView.separated(
      controller: _scrollController,
      itemCount: state.gridCells.length,
      itemBuilder: (BuildContext context, int index) {
        return _RowDetailCell(
          cellId: state.gridCells[index],
          cellBuilder: cellBuilder,
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return const VSpace(2);
      },
    );
  }

  Widget _wrapScrollbar(Widget child) {
    return ScrollbarListStack(
      axis: Axis.vertical,
      controller: _scrollController,
      barSize: GridSize.scrollBarSize,
      autoHideScrollbar: false,
      child: child,
    );
  }

  void _handleDidCreateField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    });
  }
}

class _CreateFieldButton extends StatefulWidget {
  final String viewId;
  final VoidCallback onClosed;

  const _CreateFieldButton({
    required this.viewId,
    required this.onClosed,
    Key? key,
  }) : super(key: key);

  @override
  State<_CreateFieldButton> createState() => _CreateFieldButtonState();
}

class _CreateFieldButtonState extends State<_CreateFieldButton> {
  late PopoverController popoverController;

  @override
  void initState() {
    popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(240, 200)),
      controller: popoverController,
      direction: PopoverDirection.topWithLeftAligned,
      onClose: widget.onClosed,
      child: Container(
        height: 40,
        decoration: _makeBoxDecoration(context),
        child: FlowyButton(
          text: FlowyText.medium(LocaleKeys.grid_field_newColumn.tr()),
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          onTap: () {},
          leftIcon: svgWidget("home/add"),
        ),
      ),
      popupBuilder: (BuildContext popOverContext) {
        return FieldEditor(
          gridId: widget.viewId,
          typeOptionLoader: NewFieldTypeOptionLoader(gridId: widget.viewId),
          onDeleted: (fieldId) {
            popoverController.close();

            NavigatorAlertDialog(
              title: LocaleKeys.grid_field_deleteFieldPromptMessage.tr(),
              confirm: () {
                context
                    .read<RowDetailBloc>()
                    .add(RowDetailEvent.deleteField(fieldId));
              },
            ).show(context);
          },
        );
      },
    );
  }

  BoxDecoration _makeBoxDecoration(BuildContext context) {
    final borderSide =
        BorderSide(color: Theme.of(context).dividerColor, width: 1.0);
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(top: borderSide),
    );
  }
}

class _RowDetailCell extends StatefulWidget {
  final GridCellIdentifier cellId;
  final GridCellBuilder cellBuilder;
  const _RowDetailCell({
    required this.cellId,
    required this.cellBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RowDetailCellState();
}

class _RowDetailCellState extends State<_RowDetailCell> {
  final PopoverController popover = PopoverController();

  @override
  Widget build(BuildContext context) {
    final style = _customCellStyle(widget.cellId.fieldType);
    final cell = widget.cellBuilder.build(widget.cellId, style: style);

    final gesture = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => cell.beginFocus.notify(),
      child: AccessoryHover(
        contentPadding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        child: cell,
      ),
    );

    return IntrinsicHeight(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppFlowyPopover(
              controller: popover,
              constraints: BoxConstraints.loose(const Size(240, 600)),
              margin: EdgeInsets.zero,
              triggerActions: PopoverTriggerFlags.none,
              popupBuilder: (popoverContext) => buildFieldEditor(),
              child: SizedBox(
                width: 150,
                child: FieldCellButton(
                  maxLines: null,
                  field: widget.cellId.fieldInfo.field,
                  onTap: () => popover.show(),
                ),
              ),
            ),
            const HSpace(10),
            Expanded(child: gesture),
          ],
        ),
      ),
    );
  }

  Widget buildFieldEditor() {
    return FieldEditor(
      gridId: widget.cellId.gridId,
      fieldName: widget.cellId.fieldInfo.field.name,
      isGroupField: widget.cellId.fieldInfo.isGroupField,
      typeOptionLoader: FieldTypeOptionLoader(
        gridId: widget.cellId.gridId,
        field: widget.cellId.fieldInfo.field,
      ),
      onDeleted: (fieldId) {
        popover.close();

        NavigatorAlertDialog(
          title: LocaleKeys.grid_field_deleteFieldPromptMessage.tr(),
          confirm: () {
            context
                .read<RowDetailBloc>()
                .add(RowDetailEvent.deleteField(fieldId));
          },
        ).show(context);
      },
    );
  }
}

GridCellStyle? _customCellStyle(FieldType fieldType) {
  switch (fieldType) {
    case FieldType.Checkbox:
      return null;
    case FieldType.DateTime:
      return DateCellStyle(
        alignment: Alignment.centerLeft,
      );
    case FieldType.MultiSelect:
      return SelectOptionCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
      );
    case FieldType.Checklist:
      return SelectOptionCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
      );
    case FieldType.Number:
      return null;
    case FieldType.RichText:
      return GridTextCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
      );
    case FieldType.SingleSelect:
      return SelectOptionCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
      );

    case FieldType.URL:
      return GridURLCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
        accessoryTypes: [
          GridURLCellAccessoryType.edit,
          GridURLCellAccessoryType.copyURL,
        ],
      );
  }
  throw UnimplementedError;
}
