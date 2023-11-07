import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_action_widget.dart';
import 'package:appflowy/mobile/presentation/widgets/show_flowy_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'mobile_field_type_option_editor.dart';

class CardPropertyEditScreen extends StatefulWidget {
  const CardPropertyEditScreen({super.key, required this.cellContext});

  static const routeName = '/CardPropertyEditScreen';
  static const argCellContext = 'cellContext';
  static const argRowDetailBloc = 'rowDetailBloc';

  final DatabaseCellContext cellContext;

  @override
  State<CardPropertyEditScreen> createState() => _CardPropertyEditScreenState();
}

class _CardPropertyEditScreenState extends State<CardPropertyEditScreen> {
  final propertyNameTextController = TextEditingController();
  @override
  initState() {
    super.initState();
    propertyNameTextController.text = widget.cellContext.fieldInfo.field.name;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeOptionLoader = FieldTypeOptionLoader(
      viewId: widget.cellContext.viewId,
      field: widget.cellContext.fieldInfo.field,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit property'),
        actions: [
          // TODO(yijing): improve style
          // TextButton(
          //   onPressed: () {
          //     Navigator.pop(context);
          //   },
          //   child: Text(LocaleKeys.button_done.tr()),
          // ),
          IconButton(
            onPressed: () {
              showFlowyMobileBottomSheet(
                context,
                title: 'Property Actions',
                builder: (context) => BottomSheetActionWidget(
                  svg: FlowySvgs.delete_s,
                  text: 'Delete',
                  onTap: () {
                    // replace by showFlowyMobileConfirmDialog
                    NavigatorAlertDialog(
                      title:
                          LocaleKeys.grid_field_deleteFieldPromptMessage.tr(),
                      confirm: () {
                        context.read<RowDetailBloc>().add(
                              RowDetailEvent.deleteField(
                                widget.cellContext.fieldInfo.field.id,
                              ),
                            );
                      },
                    ).show(context);
                  },
                ),
              );
            },
            icon: const Icon(Icons.more_horiz),
          ),
        ],
      ),
      body: BlocProvider(
        create: (context) {
          return FieldEditorBloc(
            // group field is the field to be used to group cards in database view, it can not be deleted
            isGroupField: false,
            loader: typeOptionLoader,
            field: typeOptionLoader.field,
          )..add(const FieldEditorEvent.initial());
        },
        child: BlocBuilder<FieldEditorBloc, FieldEditorState>(
          builder: (context, state) {
            // for field type edit option
            final dataController =
                context.read<FieldEditorBloc>().dataController;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // property name
                  // TODO(yijing): improve hint text
                  const _PropertyLabel('Name'),
                  TextField(
                    controller: propertyNameTextController,
                    onChanged: (newName) {
                      context
                          .read<FieldEditorBloc>()
                          .add(FieldEditorEvent.updateName(newName));
                    },
                  ),

                  Row(
                    children: [
                      const _PropertyLabel('Visibility'),
                      const Spacer(),
                      Switch.adaptive(
                        activeColor: Theme.of(context).colorScheme.primary,
                        // TODO(yijing): fix value didn't update here
                        value: widget.cellContext.fieldInfo.visibility ==
                            FieldVisibility.AlwaysShown,
                        onChanged: (bool value) {
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
        ),
      ),
    );
  }
}
