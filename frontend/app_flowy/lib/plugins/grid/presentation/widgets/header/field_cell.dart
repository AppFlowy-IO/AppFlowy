import 'package:app_flowy/plugins/grid/application/field/field_cell_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:appflowy_popover/popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../layout/sizes.dart';
import 'field_type_extension.dart';

import 'field_cell_action_sheet.dart';

class GridFieldCell extends StatefulWidget {
  final GridFieldCellContext cellContext;
  const GridFieldCell(this.cellContext, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GridFieldCellState();
}

class _GridFieldCellState extends State<GridFieldCell> {
  final popover = PopoverController();

  @override
  Widget build(BuildContext gridCellContext) {
    return BlocProvider(
      create: (context) => FieldCellBloc(cellContext: widget.cellContext)
        ..add(const FieldCellEvent.initial()),
      child: BlocBuilder<FieldCellBloc, FieldCellState>(
        // buildWhen: (p, c) => p.field != c.field,
        builder: (context, state) {
          final button = Popover(
            controller: popover,
            direction: PopoverDirection.bottomWithLeftAligned,
            child: FieldCellButton(
              field: state.field,
              onTap: () => popover.show(),
            ),
            offset: const Offset(0, 10),
            popupBuilder: (BuildContext context) {
              return GridFieldCellActionSheet(
                cellContext: widget.cellContext,
              );
            },
          );

          const line = Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: _DragToExpandLine(),
          );

          return _GridHeaderCellContainer(
            width: state.width,
            child: Stack(
              alignment: Alignment.centerRight,
              fit: StackFit.expand,
              children: [button, line],
            ),
          );
        },
      ),
    );
  }
}

class _GridHeaderCellContainer extends StatelessWidget {
  final Widget child;
  final double width;
  const _GridHeaderCellContainer({
    required this.child,
    required this.width,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final borderSide = BorderSide(color: theme.shader5, width: 1.0);
    final decoration = BoxDecoration(
        border: Border(
      top: borderSide,
      right: borderSide,
      bottom: borderSide,
    ));

    return Container(
      width: width,
      decoration: decoration,
      child: ConstrainedBox(
          constraints: const BoxConstraints.expand(), child: child),
    );
  }
}

class _DragToExpandLine extends StatelessWidget {
  const _DragToExpandLine({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return InkWell(
      onTap: () {},
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (value) {
          context
              .read<FieldCellBloc>()
              .add(FieldCellEvent.startUpdateWidth(value.delta.dx));
        },
        onHorizontalDragEnd: (end) {
          context
              .read<FieldCellBloc>()
              .add(const FieldCellEvent.endUpdateWidth());
        },
        child: FlowyHover(
          cursor: SystemMouseCursors.resizeLeftRight,
          style: HoverStyle(
            hoverColor: theme.main1,
            borderRadius: BorderRadius.zero,
            contentMargin: const EdgeInsets.only(left: 6),
          ),
          child: const SizedBox(width: 4),
        ),
      ),
    );
  }
}

class FieldCellButton extends StatelessWidget {
  final VoidCallback onTap;
  final FieldPB field;
  const FieldCellButton({
    required this.field,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyButton(
      hoverColor: theme.shader6,
      onTap: onTap,
      leftIcon: svgWidget(field.fieldType.iconName(), color: theme.iconColor),
      text: FlowyText.medium(field.name, fontSize: 12),
      margin: GridSize.cellContentInsets,
    );
  }
}
