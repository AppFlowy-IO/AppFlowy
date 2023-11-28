import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_cell_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../layout/sizes.dart';
import 'field_editor.dart';
import 'field_type_extension.dart';

class GridFieldCell extends StatefulWidget {
  const GridFieldCell({
    super.key,
    required this.viewId,
    required this.fieldController,
    required this.fieldInfo,
    required this.onTap,
    required this.onEditorOpened,
    required this.onFieldInsertedOnEitherSide,
    required this.isEditing,
    required this.isNew,
  });

  final String viewId;
  final FieldController fieldController;
  final FieldInfo fieldInfo;
  final VoidCallback onTap;
  final VoidCallback onEditorOpened;
  final void Function(String fieldId) onFieldInsertedOnEitherSide;
  final bool isEditing;
  final bool isNew;

  @override
  State<GridFieldCell> createState() => _GridFieldCellState();
}

class _GridFieldCellState extends State<GridFieldCell> {
  late final FieldCellBloc _bloc;
  late PopoverController popoverController;

  @override
  void initState() {
    super.initState();
    popoverController = PopoverController();
    _bloc = FieldCellBloc(viewId: widget.viewId, fieldInfo: widget.fieldInfo);
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        popoverController.show();
      });
    }
  }

  @override
  didUpdateWidget(covariant oldWidget) {
    if (widget.fieldInfo != oldWidget.fieldInfo && !_bloc.isClosed) {
      _bloc.add(FieldCellEvent.onFieldChanged(widget.fieldInfo));
    }
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        popoverController.show();
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<FieldCellBloc, FieldCellState>(
        builder: (context, state) {
          final button = AppFlowyPopover(
            triggerActions: PopoverTriggerFlags.none,
            constraints: const BoxConstraints(),
            margin: EdgeInsets.zero,
            direction: PopoverDirection.bottomWithLeftAligned,
            controller: popoverController,
            popupBuilder: (BuildContext context) {
              widget.onEditorOpened();
              return FieldEditor(
                viewId: widget.viewId,
                fieldController: widget.fieldController,
                field: widget.fieldInfo.field,
                initialPage: widget.isNew
                    ? FieldEditorPage.details
                    : FieldEditorPage.general,
                onFieldInserted: widget.onFieldInsertedOnEitherSide,
              );
            },
            child: FieldCellButton(
              field: widget.fieldInfo.field,
              onTap: widget.onTap,
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
              children: [button, line],
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await _bloc.close();
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
        right: borderSide,
        bottom: borderSide,
      ),
    );

    return Container(
      width: width,
      decoration: decoration,
      child: child,
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
        onHorizontalDragStart: (details) {
          context
              .read<FieldCellBloc>()
              .add(const FieldCellEvent.onResizeStart());
        },
        onHorizontalDragUpdate: (value) {
          context
              .read<FieldCellBloc>()
              .add(FieldCellEvent.startUpdateWidth(value.localPosition.dx));
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
  final BorderRadius? radius;
  final EdgeInsets? margin;
  const FieldCellButton({
    required this.field,
    required this.onTap,
    this.maxLines = 1,
    this.radius = BorderRadius.zero,
    this.margin,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      onTap: onTap,
      leftIcon: FlowySvg(
        field.fieldType.icon(),
        color: Theme.of(context).iconTheme.color,
      ),
      radius: radius,
      text: FlowyText.medium(
        field.name,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        color: AFThemeExtension.of(context).textColor,
      ),
      margin: margin ?? GridSize.cellContentInsets,
    );
  }
}
