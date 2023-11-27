import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/mobile_field_name_text_field.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/mobile_field_type_option_editor.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/widgets/property_title.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/application/setting/property_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/field_visibility_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileDatabasePropertyEditor extends StatefulWidget {
  const MobileDatabasePropertyEditor({
    super.key,
    required this.viewId,
    required this.fieldInfo,
    required this.fieldController,
    required this.bloc,
  });

  final String viewId;
  final FieldInfo fieldInfo;
  final FieldController fieldController;
  final DatabasePropertyBloc bloc;

  @override
  State<MobileDatabasePropertyEditor> createState() =>
      _MobileDatabasePropertyEditorState();
}

class _MobileDatabasePropertyEditorState
    extends State<MobileDatabasePropertyEditor> {
  late FieldVisibility _visibility =
      widget.fieldInfo.visibility ?? FieldVisibility.AlwaysShown;

  @override
  Widget build(BuildContext context) {
    final typeOptionLoader = FieldTypeOptionLoader(
      viewId: widget.viewId,
      field: widget.fieldInfo.field,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<DatabasePropertyBloc>.value(value: widget.bloc),
        BlocProvider<FieldEditorBloc>(
          create: (context) => FieldEditorBloc(
            viewId: widget.viewId,
            loader: typeOptionLoader,
            field: widget.fieldInfo.field,
            fieldController: widget.fieldController,
          )..add(const FieldEditorEvent.initial()),
        ),
      ],
      child: BlocBuilder<DatabasePropertyBloc, DatabasePropertyState>(
        builder: (context, _) {
          return BlocBuilder<FieldEditorBloc, FieldEditorState>(
            builder: (context, state) {
              final dataController =
                  context.read<FieldEditorBloc>().typeOptionController;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TODO(yijing): improve hint text
                    PropertyTitle(LocaleKeys.settings_user_name.tr()),
                    BlocSelector<FieldEditorBloc, FieldEditorState, String>(
                      selector: (state) => state.field.name,
                      builder: (context, fieldName) => MobileFieldNameTextField(
                        text: fieldName,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: PropertyTitle(
                            LocaleKeys.grid_field_visibility.tr(),
                          ),
                        ),
                        Toggle(
                          padding: EdgeInsets.zero,
                          value: _visibility.isVisibleState(),
                          style: ToggleStyle.mobile,
                          onChanged: (newValue) {
                            final newVisibility = _visibility.toggle();

                            context.read<DatabasePropertyBloc>().add(
                                  DatabasePropertyEvent.setFieldVisibility(
                                    widget.fieldInfo.id,
                                    newVisibility,
                                  ),
                                );

                            setState(() => _visibility = newVisibility);
                          },
                        ),
                      ],
                    ),
                    const VSpace(8),
                    if (!typeOptionLoader.field.isPrimary)
                      MobileFieldTypeOptionEditor(
                        dataController: dataController,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
