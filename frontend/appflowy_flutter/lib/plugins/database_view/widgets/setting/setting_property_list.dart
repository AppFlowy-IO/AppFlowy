import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_paginated_bottom_sheet.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/setting/property_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_editor.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/field_visibility_extension.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/mobile_database_property_editor.dart';
import 'package:appflowy/util/platform_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

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
                  bloc: _bloc,
                ),
              )
              .toList();

          if (PlatformExtension.isMobile) {
            return ListView.separated(
              shrinkWrap: true,
              itemCount: cells.length,
              itemBuilder: (_, index) => cells[index],
              separatorBuilder: (_, __) => const VSpace(8),
            );
          }

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
class DatabasePropertyCell extends StatelessWidget {
  const DatabasePropertyCell({
    super.key,
    required this.fieldInfo,
    required this.viewId,
    required this.popoverMutex,
    required this.index,
    required this.fieldController,
    required this.bloc,
  });

  final FieldInfo fieldInfo;
  final String viewId;
  final PopoverMutex popoverMutex;
  final int index;
  final FieldController fieldController;
  final DatabasePropertyBloc bloc;

  @override
  Widget build(BuildContext context) {
    if (PlatformExtension.isMobile) {
      return MobileDatabasePropertyCell(
        fieldInfo: fieldInfo,
        viewId: viewId,
        fieldController: fieldController,
        bloc: bloc,
      );
    }

    return DesktopDatabasePropertyCell(
      fieldInfo: fieldInfo,
      viewId: viewId,
      popoverMutex: popoverMutex,
      index: index,
      fieldController: fieldController,
    );
  }
}

class MobileDatabasePropertyCell extends StatefulWidget {
  const MobileDatabasePropertyCell({
    super.key,
    required this.fieldInfo,
    required this.viewId,
    required this.fieldController,
    required this.bloc,
  });

  final FieldInfo fieldInfo;
  final String viewId;
  final FieldController fieldController;
  final DatabasePropertyBloc bloc;

  @override
  State<MobileDatabasePropertyCell> createState() =>
      _MobileDatabasePropertyCellState();
}

class _MobileDatabasePropertyCellState
    extends State<MobileDatabasePropertyCell> {
  late bool isVisible = widget.fieldInfo.visibility?.isVisibleState() ?? false;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => FlowyBottomSheetController.of(context)!.push(
          SheetPage(
            title: LocaleKeys.grid_field_editProperty.tr(),
            body: MobileDatabasePropertyEditor(
              viewId: widget.viewId,
              fieldInfo: widget.fieldInfo,
              fieldController: widget.fieldController,
              bloc: widget.bloc,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              FlowySvg(
                widget.fieldInfo.fieldType.icon(),
                color: Theme.of(context).iconTheme.color,
                size: const Size.square(24),
              ),
              const HSpace(8),
              FlowyText.medium(
                widget.fieldInfo.name,
                color: AFThemeExtension.of(context).textColor,
              ),
              const Spacer(),
              // Toggle Visibility
              Toggle(
                padding: EdgeInsets.zero,
                value: isVisible,
                style: ToggleStyle.mobile,
                onChanged: (newValue) {
                  final newVisibility = widget.fieldInfo.visibility!.toggle();

                  context.read<DatabasePropertyBloc>().add(
                        DatabasePropertyEvent.setFieldVisibility(
                          widget.fieldInfo.id,
                          newVisibility,
                        ),
                      );

                  setState(() => isVisible = !newValue);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class DesktopDatabasePropertyCell extends StatefulWidget {
  const DesktopDatabasePropertyCell({
    super.key,
    required this.fieldController,
    required this.fieldInfo,
    required this.viewId,
    required this.popoverMutex,
    required this.index,
  });

  final FieldController fieldController;
  final FieldInfo fieldInfo;
  final String viewId;
  final PopoverMutex popoverMutex;
  final int index;

  @override
  State<DesktopDatabasePropertyCell> createState() =>
      _DesktopDatabasePropertyCellState();
}

class _DesktopDatabasePropertyCellState
    extends State<DesktopDatabasePropertyCell> {
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

              final newVisiblity =
                  widget.fieldInfo.fieldSettings!.visibility.toggle();
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
        ).padding(horizontal: 6.0),
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
