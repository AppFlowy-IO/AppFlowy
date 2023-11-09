import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/widgets.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/mobile_field_type_option_editor.dart';
import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Used in [CardPropertyEditScreen] and [MobileCreateRowFieldScreen]
class MobileFieldEditor extends StatelessWidget {
  const MobileFieldEditor({
    super.key,
    required this.viewId,
    required this.typeOptionLoader,
    this.isGroupingField = false,
    this.fieldInfo,
  });
  final String viewId;
  final bool isGroupingField;
  final FieldTypeOptionLoader typeOptionLoader;
  final FieldInfo? fieldInfo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return FieldEditorBloc(
          // group field is the field to be used to group cards in database view, it can not be deleted
          isGroupField: isGroupingField,
          loader: typeOptionLoader,
          field: typeOptionLoader.field,
        )..add(const FieldEditorEvent.initial());
      },
      child: BlocBuilder<FieldEditorBloc, FieldEditorState>(
        builder: (context, state) {
          // for field type edit option
          final dataController = context.read<FieldEditorBloc>().dataController;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // property name
                // TODO(yijing): improve hint text
                _PropertyLabel(LocaleKeys.settings_user_name.tr()),
                BlocSelector<FieldEditorBloc, FieldEditorState, String>(
                  selector: (state) {
                    return state.name;
                  },
                  builder: (context, propertyName) {
                    return MobileFieldNameTextField(
                      text: propertyName,
                    );
                  },
                ),
                Row(
                  children: [
                    _PropertyLabel(LocaleKeys.grid_field_visibility.tr()),
                    const Spacer(),
                    VisibilitySwitch(
                      isFieldHidden:
                          fieldInfo?.visibility == FieldVisibility.AlwaysHidden,
                      onChanged: () {
                        state.field.fold(
                          () => Log.error('Can not hidden the field'),
                          (field) => context.read<RowDetailBloc>().add(
                                RowDetailEvent.toggleFieldVisibility(
                                  field.id,
                                ),
                              ),
                        );
                      },
                    ),
                  ],
                ),
                const VSpace(8),
                // edit property type and settings
                if (!typeOptionLoader.field.isPrimary)
                  MobileFieldTypeOptionEditor(
                    dataController: dataController,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PropertyLabel extends StatelessWidget {
  const _PropertyLabel(
    this.name,
  );

  final String name;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class VisibilitySwitch extends StatefulWidget {
  const VisibilitySwitch({
    super.key,
    required this.isFieldHidden,
    this.onChanged,
  });
  final bool isFieldHidden;
  final Function? onChanged;

  @override
  State<VisibilitySwitch> createState() => _VisibilitySwitchState();
}

class _VisibilitySwitchState extends State<VisibilitySwitch> {
  late bool _isFieldHidden;
  @override
  initState() {
    super.initState();
    _isFieldHidden = widget.isFieldHidden;
  }

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      activeColor: Theme.of(context).colorScheme.primary,
      value: !_isFieldHidden,
      onChanged: (bool value) {
        setState(() {
          _isFieldHidden = !_isFieldHidden;
          widget.onChanged?.call();
        });
      },
    );
  }
}
