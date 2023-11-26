import 'package:appflowy/generated/flowy_svgs.g.dart';
import "package:appflowy/generated/locale_keys.g.dart";
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/row/accessory/cell_accessory.dart';
import '../../../../widgets/row/cells/cell_container.dart';
import '../../layout/sizes.dart';
import 'action.dart';

class GridRow extends StatefulWidget {
  final RowId viewId;
  final RowId rowId;
  final RowController dataController;
  final GridCellBuilder cellBuilder;
  final void Function(BuildContext, GridCellBuilder) openDetailPage;

  final int? index;
  final bool isDraggable;

  const GridRow({
    super.key,
    required this.viewId,
    required this.rowId,
    required this.dataController,
    required this.cellBuilder,
    required this.openDetailPage,
    this.index,
    this.isDraggable = false,
  });

  @override
  State<GridRow> createState() => _GridRowState();
}

class _GridRowState extends State<GridRow> {
  late final RowBloc _rowBloc;

  @override
  void initState() {
    super.initState();
    _rowBloc = RowBloc(
      rowId: widget.rowId,
      dataController: widget.dataController,
      viewId: widget.viewId,
    )..add(const RowEvent.initial());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _rowBloc,
      child: BlocBuilder<RowBloc, RowState>(
        // The row need to rebuild when the cell count changes.
        buildWhen: (p, c) => p.rowSource != c.rowSource,
        builder: (context, state) {
          final content = Expanded(
            child: RowContent(
              builder: widget.cellBuilder,
              onExpand: () => widget.openDetailPage(
                context,
                widget.cellBuilder,
              ),
            ),
          );

          return _RowEnterRegion(
            key: ValueKey(state.rowSource),
            child: Row(
              children: [
                _RowLeading(
                  index: widget.index,
                  isDraggable: widget.isDraggable,
                ),
                content,
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _rowBloc.close();
    super.dispose();
  }
}

class _RowLeading extends StatefulWidget {
  final int? index;
  final bool isDraggable;

  const _RowLeading({
    this.index,
    this.isDraggable = false,
  });

  @override
  State<_RowLeading> createState() => _RowLeadingState();
}

class _RowLeadingState extends State<_RowLeading> {
  late final PopoverController popoverController;

  @override
  void initState() {
    super.initState();
    popoverController = PopoverController();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      triggerActions: PopoverTriggerFlags.none,
      constraints: BoxConstraints.loose(const Size(140, 200)),
      direction: PopoverDirection.rightWithCenterAligned,
      margin: const EdgeInsets.all(6),
      popupBuilder: (BuildContext popoverContext) {
        final bloc = context.read<RowBloc>();
        return RowActions(
          viewId: bloc.viewId,
          rowId: bloc.rowId,
        );
      },
      child: Consumer<RegionStateNotifier>(
        builder: (context, state, _) {
          return SizedBox(
            width: GridSize.leadingHeaderPadding,
            child: state.onEnter ? _activeWidget() : null,
          );
        },
      ),
    );
  }

  Widget _activeWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const InsertRowButton(),
        if (isDraggable)
          ReorderableDragStartListener(
            index: widget.index!,
            child: RowMenuButton(
              isDragEnabled: isDraggable,
              openMenu: popoverController.show,
            ),
          )
        else
          RowMenuButton(
            openMenu: popoverController.show,
          ),
      ],
    );
  }

  bool get isDraggable => widget.index != null && widget.isDraggable;
}

class InsertRowButton extends StatelessWidget {
  const InsertRowButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      tooltipText: LocaleKeys.tooltip_addNewRow.tr(),
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      width: 20,
      height: 30,
      onPressed: () => context.read<RowBloc>().add(const RowEvent.createRow()),
      iconPadding: const EdgeInsets.all(3),
      icon: FlowySvg(
        FlowySvgs.add_s,
        color: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }
}

class RowMenuButton extends StatefulWidget {
  final VoidCallback openMenu;
  final bool isDragEnabled;

  const RowMenuButton({
    required this.openMenu,
    this.isDragEnabled = false,
    super.key,
  });

  @override
  State<RowMenuButton> createState() => _RowMenuButtonState();
}

class _RowMenuButtonState extends State<RowMenuButton> {
  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      tooltipText:
          widget.isDragEnabled ? null : LocaleKeys.tooltip_openMenu.tr(),
      richTooltipText: widget.isDragEnabled
          ? TextSpan(
              children: [
                TextSpan(text: '${LocaleKeys.tooltip_dragRow.tr()}\n'),
                TextSpan(text: LocaleKeys.tooltip_openMenu.tr()),
              ],
            )
          : null,
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
  final VoidCallback onExpand;
  final GridCellBuilder builder;
  const RowContent({
    required this.builder,
    required this.onExpand,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowBloc, RowState>(
      buildWhen: (previous, current) =>
          !listEquals(previous.cells, current.cells),
      builder: (context, state) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._makeCells(context, state.cellByFieldId),
              _finalCellDecoration(context),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _makeCells(
    BuildContext context,
    CellContextByFieldId cellByFieldId,
  ) {
    return cellByFieldId.values.map(
      (cellId) {
        final GridCellWidget child = builder.build(cellId);
        return CellContainer(
          width: cellId.fieldInfo.fieldSettings?.width.toDouble() ?? 140,
          isPrimary: cellId.fieldInfo.field.isPrimary,
          accessoryBuilder: (buildContext) {
            final builder = child.accessoryBuilder;
            final List<GridCellAccessoryBuilder> accessories = [];
            if (cellId.fieldInfo.field.isPrimary) {
              accessories.add(
                GridCellAccessoryBuilder(
                  builder: (key) => PrimaryCellAccessory(
                    key: key,
                    onTapCallback: onExpand,
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
        width: GridSize.trailHeaderPadding,
        padding: GridSize.headerContentInsets,
        constraints: const BoxConstraints(minHeight: 46),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
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
  final Widget child;
  const _RowEnterRegion({required this.child, Key? key}) : super(key: key);

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

  @override
  Future<void> dispose() async {
    _rowStateNotifier.dispose();
    super.dispose();
  }
}
