import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/setting/property_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/field/field_editor.dart';
import 'package:appflowy/plugins/database/widgets/setting/field_visibility_extension.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DatabasePropertyList extends StatefulWidget {
  const DatabasePropertyList({
    super.key,
    required this.viewId,
    required this.fieldController,
  });

  final String viewId;
  final FieldController fieldController;

  @override
  State<StatefulWidget> createState() => _DatabasePropertyListState();
}

class _DatabasePropertyListState extends State<DatabasePropertyList> {
  final PopoverMutex _popoverMutex = PopoverMutex();
  late final DatabasePropertyBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = DatabasePropertyBloc(
      viewId: widget.viewId,
      fieldController: widget.fieldController,
    )..add(const DatabasePropertyEvent.initial());
  }

  @override
  void dispose() {
    _popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DatabasePropertyBloc>.value(
      value: _bloc,
      child: BlocBuilder<DatabasePropertyBloc, DatabasePropertyState>(
        builder: (context, state) {
          final cells = state.fieldContexts
              .mapIndexed(
                (index, field) => DatabasePropertyCell(
                  key: ValueKey(field.id),
                  viewId: widget.viewId,
                  fieldController: widget.fieldController,
                  fieldInfo: field,
                  popoverMutex: _popoverMutex,
                  index: index,
                ),
              )
              .toList();

          return ReorderableListView(
            proxyDecorator: (child, index, _) => Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  child,
                  MouseRegion(
                    cursor: Platform.isWindows
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.grabbing,
                    child: const SizedBox.expand(),
                  ),
                ],
              ),
            ),
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            onReorder: (from, to) {
              context
                  .read<DatabasePropertyBloc>()
                  .add(DatabasePropertyEvent.moveField(from, to));
            },
            onReorderStart: (_) => _popoverMutex.close(),
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            children: cells,
          );
        },
      ),
    );
  }
}

@visibleForTesting
class DatabasePropertyCell extends StatefulWidget {
  const DatabasePropertyCell({
    super.key,
    required this.fieldInfo,
    required this.viewId,
    required this.popoverMutex,
    required this.index,
    required this.fieldController,
  });

  final FieldInfo fieldInfo;
  final String viewId;
  final PopoverMutex popoverMutex;
  final int index;
  final FieldController fieldController;

  @override
  State<DatabasePropertyCell> createState() => _DatabasePropertyCellState();
}

class _DatabasePropertyCellState extends State<DatabasePropertyCell> {
  final PopoverController _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    final visiblity = widget.fieldInfo.visibility;
    final visibleIcon = FlowySvg(
      visiblity != null && visiblity != FieldVisibility.AlwaysHidden
          ? FlowySvgs.show_m
          : FlowySvgs.hide_m,
      size: const Size.square(16),
      color: Theme.of(context).iconTheme.color,
    );

    return AppFlowyPopover(
      mutex: widget.popoverMutex,
      controller: _popoverController,
      offset: const Offset(-8, 0),
      direction: PopoverDirection.leftWithTopAligned,
      constraints: BoxConstraints.loose(const Size(240, 400)),
      triggerActions: PopoverTriggerFlags.none,
      margin: EdgeInsets.zero,
      child: Container(
        height: GridSize.popoverItemHeight,
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
        child: FlowyButton(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          text: FlowyText.medium(
            lineHeight: 1.0,
            widget.fieldInfo.name,
            color: AFThemeExtension.of(context).textColor,
          ),
          leftIconSize: const Size(36, 18),
          leftIcon: Row(
            children: [
              ReorderableDragStartListener(
                index: widget.index,
                child: MouseRegion(
                  cursor: Platform.isWindows
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.grab,
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: FlowySvg(
                      FlowySvgs.drag_element_s,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                ),
              ),
              const HSpace(6.0),
              FlowySvg(
                widget.fieldInfo.fieldType.svgData,
                color: Theme.of(context).iconTheme.color,
                size: const Size.square(16),
              ),
            ],
          ),
          rightIcon: FlowyIconButton(
            hoverColor: Colors.transparent,
            onPressed: () {
              if (widget.fieldInfo.fieldSettings == null) {
                return;
              }

              final newVisiblity = widget.fieldInfo.visibility!.toggle();
              context.read<DatabasePropertyBloc>().add(
                    DatabasePropertyEvent.setFieldVisibility(
                      widget.fieldInfo.id,
                      newVisiblity,
                    ),
                  );
            },
            icon: visibleIcon,
          ),
          onTap: () => _popoverController.show(),
        ),
      ),
      popupBuilder: (BuildContext context) {
        return FieldEditor(
          viewId: widget.viewId,
          field: widget.fieldInfo.field,
          fieldController: widget.fieldController,
        );
      },
    );
  }
}
