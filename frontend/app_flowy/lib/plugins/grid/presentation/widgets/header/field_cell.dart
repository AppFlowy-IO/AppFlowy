import 'package:app_flowy/plugins/grid/application/field/field_cell_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../layout/sizes.dart';
import 'field_type_extension.dart';

import 'field_cell_action_sheet.dart';

class GridFieldCell extends StatefulWidget {
  final GridFieldCellContext cellContext;
  const GridFieldCell({
    Key? key,
    required this.cellContext,
  }) : super(key: key);

  @override
  State<GridFieldCell> createState() => _GridFieldCellState();
}

class _GridFieldCellState extends State<GridFieldCell> {
  late PopoverController popoverController;

  @override
  void initState() {
    popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return FieldCellBloc(cellContext: widget.cellContext);
      },
      child: BlocBuilder<FieldCellBloc, FieldCellState>(
        builder: (context, state) {
          final button = AppFlowyPopover(
            triggerActions: PopoverTriggerFlags.none,
            constraints: BoxConstraints.loose(const Size(240, 440)),
            direction: PopoverDirection.bottomWithLeftAligned,
            controller: popoverController,
            popupBuilder: (BuildContext context) {
              return GridFieldCellActionSheet(
                cellContext: widget.cellContext,
              );
            },
            child: FieldCellButton(
              field: widget.cellContext.field,
              onTap: () => popoverController.show(),
            ),
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
    final borderSide = BorderSide(
      color: Theme.of(context).dividerColor,
      width: 1.0,
    );
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
            hoverColor: Theme.of(context).colorScheme.primary,
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
  final int? maxLines;
  const FieldCellButton({
    required this.field,
    required this.onTap,
    this.maxLines = 1,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Using this technique to have proper text ellipsis
    // https://github.com/flutter/flutter/issues/18761#issuecomment-812390920
    final text = Characters(field.name)
        .replaceAll(Characters(''), Characters('\u{200B}'))
        .toString();
    return FlowyButton(
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      onTap: onTap,
      leftIcon: svgWidget(
        field.fieldType.iconName(),
        color: Theme.of(context).colorScheme.onSurface,
      ),
      radius: BorderRadius.zero,
      text: FlowyText.medium(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
      margin: GridSize.cellContentInsets,
    );
  }
}
