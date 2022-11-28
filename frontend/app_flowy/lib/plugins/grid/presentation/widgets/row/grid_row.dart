import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:app_flowy/plugins/grid/application/row/row_cache.dart';
import 'package:app_flowy/plugins/grid/application/row/row_data_controller.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../layout/sizes.dart';
import '../cell/cell_accessory.dart';
import '../cell/cell_container.dart';
import '../cell/prelude.dart';
import 'row_action_sheet.dart';
import "package:app_flowy/generated/locale_keys.g.dart";
import 'package:easy_localization/easy_localization.dart';

class GridRowWidget extends StatefulWidget {
  final RowInfo rowInfo;
  final GridRowDataController dataController;
  final GridCellBuilder cellBuilder;
  final void Function(BuildContext, GridCellBuilder) openDetailPage;

  const GridRowWidget({
    required this.rowInfo,
    required this.dataController,
    required this.cellBuilder,
    required this.openDetailPage,
    Key? key,
  }) : super(key: key);

  @override
  State<GridRowWidget> createState() => _GridRowWidgetState();
}

class _GridRowWidgetState extends State<GridRowWidget> {
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
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _rowBloc,
      child: _RowEnterRegion(
        child: BlocBuilder<RowBloc, RowState>(
          buildWhen: (p, c) => p.rowInfo.rowPB.height != c.rowInfo.rowPB.height,
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

            return Row(children: [
              const _RowLeading(),
              content,
              const _RowTrailing(),
            ]);
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
  const _RowLeading({Key? key}) : super(key: key);

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
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      triggerActions: PopoverTriggerFlags.none,
      constraints: BoxConstraints.loose(const Size(140, 200)),
      direction: PopoverDirection.rightWithCenterAligned,
      margin: const EdgeInsets.all(6),
      popupBuilder: (BuildContext popoverContext) {
        return GridRowActionSheet(
            rowData: context.read<RowBloc>().state.rowInfo);
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
        const _InsertButton(),
        _MenuButton(openMenu: () {
          popoverController.show();
        }),
      ],
    );
  }
}

class _RowTrailing extends StatelessWidget {
  const _RowTrailing({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class _InsertButton extends StatelessWidget {
  const _InsertButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      tooltipText: LocaleKeys.tooltip_addNewRow.tr(),
      width: 20,
      height: 30,
      onPressed: () => context.read<RowBloc>().add(const RowEvent.createRow()),
      iconPadding: const EdgeInsets.all(3),
      icon: svgWidget("home/add"),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final VoidCallback openMenu;
  const _MenuButton({
    required this.openMenu,
    Key? key,
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
  Widget build(BuildContext context) {
    return FlowyIconButton(
      tooltipText: LocaleKeys.tooltip_openMenu.tr(),
      width: 20,
      height: 30,
      onPressed: () => widget.openMenu(),
      iconPadding: const EdgeInsets.all(3),
      icon: svgWidget("editor/details"),
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
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _makeCells(context, state.gridCellMap),
        ));
      },
    );
  }

  List<Widget> _makeCells(BuildContext context, GridCellMap gridCellMap) {
    return gridCellMap.values.map(
      (cellId) {
        final GridCellWidget child = builder.build(cellId);

        return CellContainer(
          width: cellId.fieldInfo.width.toDouble(),
          rowStateNotifier:
              Provider.of<RegionStateNotifier>(context, listen: false),
          accessoryBuilder: (buildContext) {
            final builder = child.accessoryBuilder;
            List<GridCellAccessoryBuilder> accessories = [];
            if (cellId.fieldInfo.isPrimary) {
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
  late RegionStateNotifier _rowStateNotifier;

  @override
  void initState() {
    _rowStateNotifier = RegionStateNotifier();
    super.initState();
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
