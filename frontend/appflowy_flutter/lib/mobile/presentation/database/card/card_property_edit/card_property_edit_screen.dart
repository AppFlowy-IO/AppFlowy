import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/mobile_field_editor.dart';
import 'package:appflowy/mobile/presentation/widgets/show_flowy_mobile_confirm_dialog.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CardPropertyEditScreen extends StatelessWidget {
  const CardPropertyEditScreen({
    super.key,
    required this.cellContext,
    required this.fieldController,
  });

  static const routeName = '/CardPropertyEditScreen';
  static const argCellContext = 'cellContext';
  static const argFieldController = 'fieldController';
  static const argRowDetailBloc = 'rowDetailBloc';

  final DatabaseCellContext cellContext;
  final FieldController fieldController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.grid_field_editProperty.tr()),
        actions: [
          // show delete button when this field is not used to group cards
          if (!cellContext.fieldInfo.isGroupField)
            IconButton(
              onPressed: () {
                showFlowyMobileConfirmDialog(
                  context,
                  title: LocaleKeys.grid_field_deleteFieldPromptMessage.tr(),
                  actionButtonTitle: LocaleKeys.button_delete.tr(),
                  actionButtonColor: Theme.of(context).colorScheme.error,
                  onActionButtonPressed: () {
                    context.read<RowDetailBloc>().add(
                          RowDetailEvent.deleteField(
                            cellContext.fieldInfo.field.id,
                          ),
                        );
                    context.pop();
                  },
                );
              },
              icon: const FlowySvg(FlowySvgs.m_delete_m),
            ),
        ],
      ),
      body: MobileFieldEditor(
        viewId: cellContext.viewId,
        fieldController: fieldController,
        field: cellContext.fieldInfo.field,
      ),
    );
  }
}
