import 'dart:ui';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_option_tile.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/setting/property_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/desktop_field_cell.dart';
import 'package:appflowy/plugins/database/widgets/setting/field_visibility_extension.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
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
    required this.canCreate,
  });

  final DatabaseController databaseController;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    return _MobileDatabaseFieldListBody(
      databaseController: databaseController,
      viewId: context.read<ViewBloc>().state.view.id,
      canCreate: canCreate,
    );
  }
}

class _MobileDatabaseFieldListBody extends StatelessWidget {
  const _MobileDatabaseFieldListBody({
    required this.databaseController,
    required this.viewId,
    required this.canCreate,
  });

  final DatabaseController databaseController;
  final String viewId;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DatabasePropertyBloc>(
      create: (_) => DatabasePropertyBloc(
        viewId: viewId,
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
            viewId: viewId,
            fieldController: databaseController.fieldController,
            fieldInfo: firstField,
            showTopBorder: false,
          );
          final cells = fields
              .mapIndexed(
                (index, field) => DatabaseFieldListTile(
                  key: ValueKey(field.id),
                  viewId: viewId,
                  fieldController: databaseController.fieldController,
                  fieldInfo: field,
                  index: index,
                  showTopBorder: false,
                ),
              )
              .toList();

          return ReorderableListView.builder(
            padding: EdgeInsets.zero,
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
                        viewId: viewId,
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
            shrinkWrap: true,
            onReorder: (from, to) {
              from++;
              to++;
              context
                  .read<DatabasePropertyBloc>()
                  .add(DatabasePropertyEvent.moveField(from, to));
            },
            header: firstCell,
            footer: canCreate
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _divider(),
                      _NewDatabaseFieldTile(viewId: viewId),
                      VSpace(
                        context.bottomSheetPadding(
                          ignoreViewPadding: false,
                        ),
                      ),
                    ],
                  )
                : VSpace(
                    context.bottomSheetPadding(ignoreViewPadding: false),
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
        leftIcon: FieldIcon(
          fieldInfo: fieldInfo,
          dimension: 20,
        ),
        showTopBorder: showTopBorder,
      );
    } else {
      return FlowyOptionTile.toggle(
        isSelected: fieldInfo.visibility?.isVisibleState() ?? false,
        text: fieldInfo.name,
        leftIcon: FieldIcon(
          fieldInfo: fieldInfo,
          dimension: 20,
        ),
        showTopBorder: showTopBorder,
        onTap: () => showEditFieldScreen(context, viewId, fieldInfo),
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
      onTap: () => mobileCreateFieldWorkflow(context, viewId),
    );
  }
}
