import 'package:appflowy/plugins/database/domain/sort_service.dart';
import 'package:appflowy/plugins/database/grid/application/grid_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import "package:appflowy/generated/locale_keys.g.dart";
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/grid/application/row/row_bloc.dart';
import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/row/accessory/cell_accessory.dart';
import '../../../../widgets/row/cells/cell_container.dart';
import '../../layout/sizes.dart';

import 'action.dart';

class GridRow extends StatelessWidget {
  const GridRow({
    super.key,
    required this.fieldController,
    required this.viewId,
    required this.rowId,
    required this.rowController,
    required this.cellBuilder,
    required this.openDetailPage,
    required this.index,
  });

  final FieldController fieldController;
  final String viewId;
  final RowId rowId;
  final RowController rowController;
  final EditableCellBuilder cellBuilder;
  final void Function(BuildContext context) openDetailPage;
  final int index;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RowBloc(
        fieldController: fieldController,
        rowId: rowId,
        rowController: rowController,
        viewId: viewId,
      ),
      child: _RowEnterRegion(
        child: Row(
          children: [
            _RowLeading(
              viewId: viewId,
              index: index,
            ),
            Expanded(
              child: RowContent(
                fieldController: fieldController,
                cellBuilder: cellBuilder,
                onExpand: () => openDetailPage(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowLeading extends StatefulWidget {
  const _RowLeading({
    required this.viewId,
    required this.index,
  });

  final String viewId;
  final int index;

  @override
  State<_RowLeading> createState() => _RowLeadingState();
}

class _RowLeadingState extends State<_RowLeading> {
  final PopoverController popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      triggerActions: PopoverTriggerFlags.none,
      constraints: BoxConstraints.loose(const Size(200, 200)),
      direction: PopoverDirection.rightWithCenterAligned,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      popupBuilder: (_) {
        final bloc = context.read<RowBloc>();
        return BlocProvider.value(
          value: context.read<GridBloc>(),
          child: RowActionMenu(
            viewId: bloc.viewId,
            rowId: bloc.rowId,
          ),
        );
      },
      child: Consumer<RegionStateNotifier>(
        builder: (context, state, _) {
          return SizedBox(
            width: context
                .read<DatabasePluginWidgetBuilderSize>()
                .horizontalPadding,
            child: state.onEnter ? _activeWidget() : null,
          );
        },
      ),
    );
  }

  Widget _activeWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        InsertRowButton(viewId: widget.viewId),
        ReorderableDragStartListener(
          index: widget.index,
          child: RowMenuButton(
            openMenu: popoverController.show,
          ),
        ),
      ],
    );
  }
}

class InsertRowButton extends StatelessWidget {
  const InsertRowButton({
    super.key,
    required this.viewId,
  });

  final String viewId;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      tooltipText: LocaleKeys.tooltip_addNewRow.tr(),
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      width: 20,
      height: 30,
      onPressed: () {
        final rowBloc = context.read<RowBloc>();
        if (context.read<GridBloc>().state.sorts.isNotEmpty) {
          showCancelAndDeleteDialog(
            context: context,
            title: LocaleKeys.grid_sort_sortsActive.tr(
              namedArgs: {
                'intention': LocaleKeys.grid_row_createRowBelowDescription.tr(),
              },
            ),
            description: LocaleKeys.grid_sort_removeSorting.tr(),
            confirmLabel: LocaleKeys.button_remove.tr(),
            closeOnAction: true,
            onDelete: () {
              SortBackendService(viewId: viewId).deleteAllSorts();
              rowBloc.add(const RowEvent.createRow());
            },
          );
        } else {
          rowBloc.add(const RowEvent.createRow());
        }
      },
      iconPadding: const EdgeInsets.all(3),
      icon: FlowySvg(
        FlowySvgs.add_s,
        color: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }
}

class RowMenuButton extends StatefulWidget {
  const RowMenuButton({
    super.key,
    required this.openMenu,
  });

  final VoidCallback openMenu;

  @override
  State<RowMenuButton> createState() => _RowMenuButtonState();
}

class _RowMenuButtonState extends State<RowMenuButton> {
  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      richTooltipText: TextSpan(
        children: [
          TextSpan(
            text: '${LocaleKeys.tooltip_dragRow.tr()}\n',
            style: context.tooltipTextStyle(),
          ),
          TextSpan(
            text: LocaleKeys.tooltip_openMenu.tr(),
            style: context.tooltipTextStyle(),
          ),
        ],
      ),
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      width: 20,
      height: 30,
      onPressed: () => widget.openMenu(),
      iconPadding: const EdgeInsets.all(3),
      icon: FlowySvg(
        FlowySvgs.drag_element_s,
        color: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }
}

class RowContent extends StatelessWidget {
  const RowContent({
    super.key,
    required this.fieldController,
    required this.cellBuilder,
    required this.onExpand,
  });

  final FieldController fieldController;
  final VoidCallback onExpand;
  final EditableCellBuilder cellBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowBloc, RowState>(
      builder: (context, state) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._makeCells(context, state.cellContexts),
              _finalCellDecoration(context),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _makeCells(
    BuildContext context,
    List<CellContext> cellContexts,
  ) {
    return cellContexts.map(
      (cellContext) {
        final fieldInfo = fieldController.getField(cellContext.fieldId)!;
        final EditableCellWidget child = cellBuilder.buildStyled(
          cellContext,
          EditableCellStyle.desktopGrid,
        );
        return CellContainer(
          width: fieldInfo.width!.toDouble(),
          isPrimary: fieldInfo.field.isPrimary,
          accessoryBuilder: (buildContext) {
            final builder = child.accessoryBuilder;
            final List<GridCellAccessoryBuilder> accessories = [];
            if (fieldInfo.field.isPrimary) {
              accessories.add(
                GridCellAccessoryBuilder(
                  builder: (key) => PrimaryCellAccessory(
                    key: key,
                    onTap: onExpand,
                    isCellEditing: buildContext.isCellEditing,
                  ),
                ),
              );
            }

            if (builder != null) {
              accessories.addAll(builder(buildContext));
            }

            return accessories;
          },
          child: child,
        );
      },
    ).toList();
  }

  Widget _finalCellDecoration(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: Container(
        width: GridSize.newPropertyButtonWidth,
        constraints: const BoxConstraints(minHeight: 36),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AFThemeExtension.of(context).borderColor),
          ),
        ),
      ),
    );
  }
}

class RegionStateNotifier extends ChangeNotifier {
  bool _onEnter = false;

  set onEnter(bool value) {
    if (_onEnter != value) {
      _onEnter = value;
      notifyListeners();
    }
  }

  bool get onEnter => _onEnter;
}

class _RowEnterRegion extends StatefulWidget {
  const _RowEnterRegion({required this.child});

  final Widget child;

  @override
  State<_RowEnterRegion> createState() => _RowEnterRegionState();
}

class _RowEnterRegionState extends State<_RowEnterRegion> {
  late final RegionStateNotifier _rowStateNotifier;

  @override
  void initState() {
    super.initState();
    _rowStateNotifier = RegionStateNotifier();
  }

  @override
  Future<void> dispose() async {
    _rowStateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _rowStateNotifier,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (p) => _rowStateNotifier.onEnter = true,
        onExit: (p) => _rowStateNotifier.onEnter = false,
        child: widget.child,
      ),
    );
  }
}
