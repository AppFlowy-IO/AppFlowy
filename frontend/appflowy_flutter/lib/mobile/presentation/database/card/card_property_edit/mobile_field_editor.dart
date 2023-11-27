import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/widgets.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/mobile_field_type_option_editor.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/widgets/property_title.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/field_visibility_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Used in [CardPropertyEditScreen] and [MobileCreateRowFieldScreen]
class MobileFieldEditor extends StatelessWidget {
  const MobileFieldEditor({
    super.key,
    required this.viewId,
    required this.field,
    required this.fieldController,
  });

  final String viewId;
  final FieldController fieldController;
  final FieldPB field;

  @override
  Widget build(BuildContext context) {
    final typeOptionLoader = FieldTypeOptionLoader(
      viewId: viewId,
      field: field,
    );

    return BlocProvider(
      create: (context) {
        return FieldEditorBloc(
          viewId: viewId,
          loader: typeOptionLoader,
          field: field,
          fieldController: fieldController,
        )..add(const FieldEditorEvent.initial());
      },
      child: BlocBuilder<FieldEditorBloc, FieldEditorState>(
        builder: (context, state) {
          // for field type edit option
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
                  builder: (context, fieldName) =>
                      MobileFieldNameTextField(text: fieldName),
                ),
                Row(
                  children: [
                    Expanded(
                      child: PropertyTitle(
                        LocaleKeys.grid_field_visibility.tr(),
                      ),
                    ),
                    VisibilitySwitch(
                      isVisible:
                          state.field.visibility?.isVisibleState() ?? false,
                      onChanged: () => context.read<RowDetailBloc>().add(
                            RowDetailEvent.toggleFieldVisibility(
                              state.field.id,
                            ),
                          ),
                    ),
                  ],
                ),
                const VSpace(8),
                // edit property type and settings
                if (!typeOptionLoader.field.isPrimary)
                  MobileFieldTypeOptionEditor(dataController: dataController),
              ],
            ),
          );
        },
      ),
    );
  }
}

class VisibilitySwitch extends StatefulWidget {
  const VisibilitySwitch({
    super.key,
    required this.isVisible,
    this.onChanged,
  });

  final bool isVisible;
  final Function? onChanged;

  @override
  State<VisibilitySwitch> createState() => _VisibilitySwitchState();
}

class _VisibilitySwitchState extends State<VisibilitySwitch> {
  late bool _isVisible = widget.isVisible;

  @override
  Widget build(BuildContext context) {
    return Toggle(
      padding: EdgeInsets.zero,
      value: _isVisible,
      style: ToggleStyle.mobile,
      onChanged: (newValue) {
        widget.onChanged?.call();
        setState(() => _isVisible = newValue);
      },
    );
  }
}
