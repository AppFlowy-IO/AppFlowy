import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/widgets.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/mobile_field_type_option_editor.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/widgets/widgets.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/field_visibility_extension.dart';
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
          final fieldInfoVisibility =
              fieldController.getField(field.id)?.visibility;
          return Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.secondary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PropertyEditGroupTitle(LocaleKeys.settings_user_name.tr()),
                BlocSelector<FieldEditorBloc, FieldEditorState, String>(
                  selector: (state) => state.field.name,
                  builder: (context, fieldName) =>
                      MobileFieldNameTextField(text: fieldName),
                ),
                const VSpace(16),
                PropertyEditGroupTitle(LocaleKeys.grid_field_visibility.tr()),
                PropertyEditContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PropertyTitle(
                        LocaleKeys.board_showOnCard.tr(),
                      ),
                      VisibilitySwitch(
                        isFieldHidden: !(fieldInfoVisibility != null
                            ? fieldInfoVisibility.isVisibleState()
                            : field.visibility),
                        onChanged: () => context.read<RowDetailBloc>().add(
                              RowDetailEvent.toggleFieldVisibility(
                                state.field.id,
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
                const VSpace(16),
                PropertyEditGroupTitle(LocaleKeys.board_setting.tr()),
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
    required this.isFieldHidden,
    this.onChanged,
  });

  final bool isFieldHidden;
  final Function? onChanged;

  @override
  State<VisibilitySwitch> createState() => _VisibilitySwitchState();
}

class _VisibilitySwitchState extends State<VisibilitySwitch> {
  late bool _isFieldHidden = widget.isFieldHidden;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: !_isFieldHidden,
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: (value) {
        setState(() {
          _isFieldHidden = !_isFieldHidden;
          widget.onChanged?.call();
        });
      },
    );
  }
}
