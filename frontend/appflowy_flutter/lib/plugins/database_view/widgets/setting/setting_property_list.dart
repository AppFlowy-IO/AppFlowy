import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/application/setting/property_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';

import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../grid/presentation/layout/sizes.dart';
import '../../grid/presentation/widgets/header/field_editor.dart';

class DatabasePropertyList extends StatefulWidget {
  final String viewId;
  final FieldController fieldController;

  const DatabasePropertyList({
    super.key,
    required this.viewId,
    required this.fieldController,
  });

  @override
  State<StatefulWidget> createState() => _DatabasePropertyListState();
}

class _DatabasePropertyListState extends State<DatabasePropertyList> {
  final PopoverMutex _popoverMutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DatabasePropertyBloc(
        viewId: widget.viewId,
        fieldController: widget.fieldController,
      )..add(const DatabasePropertyEvent.initial()),
      child: BlocBuilder<DatabasePropertyBloc, DatabasePropertyState>(
        builder: (context, state) {
          final cells = state.fieldContexts.mapIndexed((index, field) {
            return DatabasePropertyCell(
              key: ValueKey(field.id),
              viewId: widget.viewId,
              fieldInfo: field,
              popoverMutex: _popoverMutex,
              index: index,
            );
          }).toList();

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
              context.read<DatabasePropertyBloc>().add(
                    DatabasePropertyEvent.moveField(
                      fieldId: cells[from].fieldInfo.id,
                      fromIndex: from,
                      toIndex: to,
                    ),
                  );
            },
            onReorderStart: (_) => _popoverMutex.close(),
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            children: cells,
          );
        },
      ),
    );
  }
}

@visibleForTesting
class DatabasePropertyCell extends StatefulWidget {
  final FieldInfo fieldInfo;
  final String viewId;
  final PopoverMutex popoverMutex;
  final int index;

  const DatabasePropertyCell({
    super.key,
    required this.fieldInfo,
    required this.viewId,
    required this.popoverMutex,
    required this.index,
  });

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
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FlowyButton(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          text: FlowyText.medium(
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
                widget.fieldInfo.fieldType.icon(),
                color: Theme.of(context).iconTheme.color,
              ),
            ],
          ),
          rightIcon: FlowyIconButton(
            hoverColor: Colors.transparent,
            onPressed: () {
              if (widget.fieldInfo.fieldSettings == null) {
                return;
              }

              final newVisiblity = _newFieldVisibility(
                widget.fieldInfo.fieldSettings!.visibility,
              );
              context.read<DatabasePropertyBloc>().add(
                    DatabasePropertyEvent.setFieldVisibility(
                      widget.fieldInfo.id,
                      newVisiblity,
                    ),
                  );
            },
            icon: visibleIcon.padding(all: 4.0),
          ),
          onTap: () => _popoverController.show(),
        ).padding(horizontal: 6.0),
      ),
      popupBuilder: (BuildContext context) {
        return FieldEditor(
          viewId: widget.viewId,
          fieldInfo: widget.fieldInfo,
          typeOptionLoader: FieldTypeOptionLoader(
            viewId: widget.viewId,
            field: widget.fieldInfo.field,
          ),
        );
      },
    );
  }

  FieldVisibility _newFieldVisibility(FieldVisibility current) {
    return switch (current) {
      FieldVisibility.AlwaysShown => FieldVisibility.AlwaysHidden,
      FieldVisibility.AlwaysHidden => FieldVisibility.AlwaysShown,
      _ => FieldVisibility.AlwaysHidden,
    };
  }
}
