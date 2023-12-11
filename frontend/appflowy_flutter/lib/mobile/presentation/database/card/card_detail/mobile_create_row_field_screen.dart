import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/mobile_field_editor.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileCreateRowFieldScreen extends StatefulWidget {
  static const routeName = '/MobileCreateRowFieldScreen';
  static const argViewId = 'viewId';
  static const argFieldController = 'fieldController';
  static const argTypeOption = 'typeOption';

  const MobileCreateRowFieldScreen({
    super.key,
    required this.viewId,
    required this.typeOption,
    required this.fieldController,
  });

  final String viewId;
  final FieldController fieldController;
  final TypeOptionPB typeOption;

  @override
  State<MobileCreateRowFieldScreen> createState() =>
      _MobileCreateRowFieldScreenState();
}

class _MobileCreateRowFieldScreenState
    extends State<MobileCreateRowFieldScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.grid_field_newProperty.tr()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text(
                LocaleKeys.button_done.tr(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: MobileFieldEditor(
        viewId: widget.viewId,
        fieldController: widget.fieldController,
        field: widget.typeOption.field_2,
      ),
    );
  }
}
