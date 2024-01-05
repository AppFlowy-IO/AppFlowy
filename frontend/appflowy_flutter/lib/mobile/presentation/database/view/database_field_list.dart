import 'dart:ui';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_option_tile.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/setting/property_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/plugins/database/widgets/setting/field_visibility_extension.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../field/mobile_field_bottom_sheets.dart';

class MobileDatabaseFieldList extends StatelessWidget {
  const MobileDatabaseFieldList({
    super.key,
    required this.databaseController,
  });

  final DatabaseController databaseController;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      snap: true,
      initialChildSize: 1.0,
      minChildSize: 0.0,
      builder: (context, controller) {
        return Material(
          child: Column(
            children: [
              const Center(child: DragHandler()),
              const _MobileDatabaseFieldListHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: _MobileDatabaseFieldListBody(
                    databaseController: databaseController,
                    view: context.read<ViewBloc>().state.view,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileDatabaseFieldListHeader extends StatelessWidget {
  const _MobileDatabaseFieldListHeader();

  @override
  Widget build(BuildContext context) {
    const iconWidth = 30.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FlowyIconButton(
              icon: const FlowySvg(
                FlowySvgs.arrow_left_m,
                size: Size.square(iconWidth),
              ),
              width: iconWidth,
              iconPadding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: FlowyText.medium(
              LocaleKeys.grid_settings_properties.tr(),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileDatabaseFieldListBody extends StatelessWidget {
  const _MobileDatabaseFieldListBody({
    required this.databaseController,
    required this.view,
  });

  final DatabaseController databaseController;
  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DatabasePropertyBloc>(
      create: (_) => DatabasePropertyBloc(
        viewId: view.id,
        fieldController: databaseController.fieldController,
      )..add(const DatabasePropertyEvent.initial()),
      child: BlocBuilder<DatabasePropertyBloc, DatabasePropertyState>(
        builder: (context, state) {
          if (state.fieldContexts.isEmpty) {
            return const SizedBox.shrink();
          }
          final fields = [...state.fieldContexts];
          final firstField = fields.removeAt(0);
          final firstCell = DatabaseFieldListTile(
            key: ValueKey(firstField.id),
            viewId: view.id,
            fieldController: databaseController.fieldController,
            fieldInfo: firstField,
            showTopBorder: true,
          );
          final cells = fields
              .mapIndexed(
                (index, field) => DatabaseFieldListTile(
                  key: ValueKey(field.id),
                  viewId: view.id,
                  fieldController: databaseController.fieldController,
                  fieldInfo: field,
                  index: index,
                  showTopBorder: false,
                ),
              )
              .toList();

          return ReorderableListView.builder(
            proxyDecorator: (_, index, anim) {
              final field = fields[index];
              return AnimatedBuilder(
                animation: anim,
                builder: (BuildContext context, Widget? child) {
                  final double animValue =
                      Curves.easeInOut.transform(anim.value);
                  final double scale = lerpDouble(1, 1.05, animValue)!;
                  return Transform.scale(
                    scale: scale,
                    child: Material(
                      child: DatabaseFieldListTile(
                        key: ValueKey(field.id),
                        viewId: view.id,
                        fieldController: databaseController.fieldController,
                        fieldInfo: field,
                        index: index,
                        showTopBorder: true,
                      ),
                    ),
                  );
                },
              );
            },
            buildDefaultDragHandles: true,
            shrinkWrap: true,
            onReorder: (from, to) {
              from++;
              to++;
              context
                  .read<DatabasePropertyBloc>()
                  .add(DatabasePropertyEvent.moveField(from, to));
            },
            header: firstCell,
            footer: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _divider(),
                _NewDatabaseFieldTile(viewId: view.id),
              ],
            ),
            itemCount: cells.length,
            itemBuilder: (context, index) => cells[index],
          );
        },
      ),
    );
  }

  Widget _divider() => const VSpace(20);
}

class DatabaseFieldListTile extends StatelessWidget {
  const DatabaseFieldListTile({
    super.key,
    this.index,
    required this.fieldInfo,
    required this.viewId,
    required this.fieldController,
    required this.showTopBorder,
  });

  final int? index;
  final FieldInfo fieldInfo;
  final String viewId;
  final FieldController fieldController;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    if (fieldInfo.field.isPrimary) {
      return FlowyOptionTile.text(
        text: fieldInfo.name,
        leftIcon: FlowySvg(
          fieldInfo.fieldType.icon(),
          size: const Size.square(20),
        ),
        showTopBorder: showTopBorder,
      );
    } else {
      return FlowyOptionTile.toggle(
        isSelected: fieldInfo.visibility?.isVisibleState() ?? false,
        text: fieldInfo.name,
        leftIcon: FlowySvg(
          fieldInfo.fieldType.icon(),
          size: const Size.square(20),
        ),
        showTopBorder: showTopBorder,
        onTap: () {
          showEditFieldScreen(context, viewId, fieldInfo);
        },
        onValueChanged: (value) {
          final newVisibility = fieldInfo.visibility!.toggle();
          context.read<DatabasePropertyBloc>().add(
                DatabasePropertyEvent.setFieldVisibility(
                  fieldInfo.id,
                  newVisibility,
                ),
              );
        },
      );
    }
  }
}

class _NewDatabaseFieldTile extends StatelessWidget {
  const _NewDatabaseFieldTile({required this.viewId});

  final String viewId;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.text(
      text: LocaleKeys.grid_field_newProperty.tr(),
      leftIcon: FlowySvg(
        FlowySvgs.add_s,
        size: const Size.square(20),
        color: Theme.of(context).hintColor,
      ),
      textColor: Theme.of(context).hintColor,
      onTap: () => showCreateFieldBottomSheet(context, viewId),
    );
  }
}
