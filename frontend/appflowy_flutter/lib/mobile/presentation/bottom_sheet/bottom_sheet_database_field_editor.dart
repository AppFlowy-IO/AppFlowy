import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'bottom_sheet_action_widget.dart';
import 'bottom_sheet_database_field_header.dart';
import 'bottom_sheet_rename_widget.dart';

/// The mobile bottom bar field editor is a two-deep menu. The type option
/// sub-menu may have its own sub-menus as well though.
enum MobileDBBottomSheetViewMode {
  // operations shared between all fields
  general,
  // operations specific to the field type
  typeOption,
}

class MobileDBBottomSheetFieldEditor extends StatefulWidget {
  final String viewId;
  final FieldController fieldController;
  final FieldPB field;
  final MobileDBBottomSheetViewMode initialPage;

  const MobileDBBottomSheetFieldEditor({
    super.key,
    required this.viewId,
    required this.fieldController,
    required this.field,
    this.initialPage = MobileDBBottomSheetViewMode.general,
  });

  @override
  State<MobileDBBottomSheetFieldEditor> createState() =>
      _MobileDBBottomSheetFieldEditorState();
}

class _MobileDBBottomSheetFieldEditorState
    extends State<MobileDBBottomSheetFieldEditor> {
  late MobileDBBottomSheetViewMode viewMode;
  late final FieldEditorBloc _fieldEditorBloc;

  @override
  void initState() {
    super.initState();
    viewMode = widget.initialPage;
    final loader = FieldTypeOptionLoader(
      viewId: widget.viewId,
      field: widget.field,
    );
    _fieldEditorBloc = FieldEditorBloc(
      viewId: widget.viewId,
      field: widget.field,
      loader: loader,
      fieldController: widget.fieldController,
    )..add(const FieldEditorEvent.initial());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FieldEditorBloc>.value(
      value: _fieldEditorBloc,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const VSpace(16),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return MobileDBFieldBottomSheetHeader(
      showBackButton: viewMode == MobileDBBottomSheetViewMode.typeOption,
      onBack: () {
        if (viewMode == MobileDBBottomSheetViewMode.typeOption) {
          setState(() {
            viewMode = MobileDBBottomSheetViewMode.general;
          });
        }
      },
    );
  }

  Widget _buildBody() {
    return switch (viewMode) {
      MobileDBBottomSheetViewMode.general => MobileDBFieldBottomSheetBody(
          onAction: (action) {
            switch (action) {
              case MobileDBBottomSheetGeneralAction.typeOption:
                break;
              case MobileDBBottomSheetGeneralAction.toggleVisibility:
                _fieldEditorBloc
                    .add(const FieldEditorEvent.toggleFieldVisibility());
                context.pop();
                break;
              case MobileDBBottomSheetGeneralAction.delete:
                _fieldEditorBloc.add(const FieldEditorEvent.deleteField());
                context.pop();
                break;
              case MobileDBBottomSheetGeneralAction.duplicate:
                _fieldEditorBloc.add(const FieldEditorEvent.duplicateField());
                context.pop();
            }
          },
          onRename: (name) {
            _fieldEditorBloc.add(FieldEditorEvent.renameField(name));
          },
        ),
      MobileDBBottomSheetViewMode.typeOption => const SizedBox.shrink(),
    };
  }
}

enum MobileDBBottomSheetGeneralAction {
  toggleVisibility,
  duplicate,
  delete,
  typeOption,
}

class MobileDBFieldBottomSheetBody extends StatelessWidget {
  const MobileDBFieldBottomSheetBody({
    super.key,
    required this.onAction,
    required this.onRename,
  });

  final void Function(MobileDBBottomSheetGeneralAction action) onAction;
  final void Function(String name) onRename;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // field name editor
        MobileBottomSheetRenameWidget(
          name: context.read<FieldEditorBloc>().state.field.name,
          onRename: (newName) => onRename(newName),
          padding: EdgeInsets.zero,
        ),
        const VSpace(8),
        // type option button
        BottomSheetActionWidget(
          svg: FlowySvgs.date_s,
          text: LocaleKeys.grid_field_editProperty.tr(),
          onTap: () => onAction(MobileDBBottomSheetGeneralAction.typeOption),
        ),
        const VSpace(8),
        Row(
          children: [
            // hide/show field
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.hide_m,
                text: LocaleKeys.grid_field_hide.tr(),
                onTap: () =>
                    onAction(MobileDBBottomSheetGeneralAction.toggleVisibility),
              ),
            ),
            const HSpace(8),
            // duplicate field
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.copy_s,
                text: LocaleKeys.grid_field_duplicate.tr(),
                onTap: () {
                  onAction(MobileDBBottomSheetGeneralAction.duplicate);
                },
              ),
            ),
          ],
        ),
        const VSpace(8),
        Row(
          children: [
            // delete field
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.delete_s,
                text: LocaleKeys.grid_field_delete.tr(),
                onTap: () {
                  onAction(MobileDBBottomSheetGeneralAction.delete);
                },
              ),
            ),
            const HSpace(8),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }
}
