import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_data_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/row/accessory/cell_accessory.dart';
import '../../layout/sizes.dart';
import '../../../../widgets/row/cells/cell_container.dart';
import 'action.dart';
import "package:appflowy/generated/locale_keys.g.dart";
import 'package:easy_localization/easy_localization.dart';

class GridRow extends StatefulWidget {
  final RowInfo rowInfo;
  final RowController dataController;
  final GridCellBuilder cellBuilder;
  final void Function(BuildContext, GridCellBuilder) openDetailPage;

  const GridRow({
    required this.rowInfo,
    required this.dataController,
    required this.cellBuilder,
    required this.openDetailPage,
    final Key? key,
  }) : super(key: key);

  @override
  State<GridRow> createState() => _GridRowState();
}

class _GridRowState extends State<GridRow> {
  late RowBloc _rowBloc;

  @override
  void initState() {
    _rowBloc = RowBloc(
      rowInfo: widget.rowInfo,
      dataController: widget.dataController,
    );
    _rowBloc.add(const RowEvent.initial());
    super.initState();
  }

  @override
  Widget build(final BuildContext context) {
    return BlocProvider.value(
      value: _rowBloc,
      child: _RowEnterRegion(
        child: BlocBuilder<RowBloc, RowState>(
          buildWhen: (final p, final c) =>
              p.rowInfo.rowPB.height != c.rowInfo.rowPB.height,
          builder: (final context, final state) {
            final content = Expanded(
              child: RowContent(
                builder: widget.cellBuilder,
                onExpand: () => widget.openDetailPage(
                  context,
                  widget.cellBuilder,
                ),
              ),
            );

            return Row(
              children: [
                const _RowLeading(),
                content,
                const _RowTrailing(),
              ],
            );
          },
        ),
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
  const _RowLeading({final Key? key}) : super(key: key);

  @override
  State<_RowLeading> createState() => _RowLeadingState();
}

class _RowLeadingState extends State<_RowLeading> {
  late PopoverController popoverController;

  @override
  void initState() {
    popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(final BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      triggerActions: PopoverTriggerFlags.none,
      constraints: BoxConstraints.loose(const Size(140, 200)),
      direction: PopoverDirection.rightWithCenterAligned,
      margin: const EdgeInsets.all(6),
      popupBuilder: (final BuildContext popoverContext) {
        return RowActions(rowData: context.read<RowBloc>().state.rowInfo);
      },
      child: Consumer<RegionStateNotifier>(
        builder: (final context, final state, final _) {
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
        const _InsertButton(),
        _MenuButton(
          openMenu: () {
            popoverController.show();
          },
        ),
      ],
    );
  }
}

class _RowTrailing extends StatelessWidget {
  const _RowTrailing({final Key? key}) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return const SizedBox();
  }
}

class _InsertButton extends StatelessWidget {
  const _InsertButton({final Key? key}) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return FlowyIconButton(
      tooltipText: LocaleKeys.tooltip_addNewRow.tr(),
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      width: 20,
      height: 30,
      onPressed: () => context.read<RowBloc>().add(const RowEvent.createRow()),
      iconPadding: const EdgeInsets.all(3),
      icon: svgWidget(
        'home/add',
        color: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final VoidCallback openMenu;
  const _MenuButton({
    required this.openMenu,
    final Key? key,
  }) : super(key: key);

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(final BuildContext context) {
    return FlowyIconButton(
      tooltipText: LocaleKeys.tooltip_openMenu.tr(),
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      width: 20,
      height: 30,
      onPressed: () => widget.openMenu(),
      iconPadding: const EdgeInsets.all(3),
      icon: svgWidget(
        'editor/details',
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
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return BlocBuilder<RowBloc, RowState>(
      buildWhen: (final previous, final current) =>
          !listEquals(previous.cells, current.cells),
      builder: (final context, final state) {
        return IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _makeCells(context, state.cellByFieldId),
          ),
        );
      },
    );
  }

  List<Widget> _makeCells(
    final BuildContext context,
    final CellByFieldId cellByFieldId,
  ) {
    return cellByFieldId.values.map(
      (final cellId) {
        final GridCellWidget child = builder.build(cellId);

        return CellContainer(
          width: cellId.fieldInfo.width.toDouble(),
          isPrimary: cellId.fieldInfo.isPrimary,
          cellContainerNotifier: CellContainerNotifier(child),
          accessoryBuilder: (final buildContext) {
            final builder = child.accessoryBuilder;
            final List<GridCellAccessoryBuilder> accessories = [];
            if (cellId.fieldInfo.isPrimary) {
              accessories.add(
                GridCellAccessoryBuilder(
                  builder: (final key) => PrimaryCellAccessory(
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
}

class RegionStateNotifier extends ChangeNotifier {
  bool _onEnter = false;

  set onEnter(final bool value) {
    if (_onEnter != value) {
      _onEnter = value;
      notifyListeners();
    }
  }

  bool get onEnter => _onEnter;
}

class _RowEnterRegion extends StatefulWidget {
  final Widget child;
  const _RowEnterRegion({required this.child, final Key? key})
      : super(key: key);

  @override
  State<_RowEnterRegion> createState() => _RowEnterRegionState();
}

class _RowEnterRegionState extends State<_RowEnterRegion> {
  late RegionStateNotifier _rowStateNotifier;

  @override
  void initState() {
    _rowStateNotifier = RegionStateNotifier();
    super.initState();
  }

  @override
  Widget build(final BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _rowStateNotifier,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final p) => _rowStateNotifier.onEnter = true,
        onExit: (final p) => _rowStateNotifier.onEnter = false,
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
