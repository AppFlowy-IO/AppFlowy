import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/_new_field_option.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileNewPropertyScreen extends StatefulWidget {
  static const routeName = '/new_property';
  static const argViewId = 'view_id';

  const MobileNewPropertyScreen({
    super.key,
    required this.viewId,
  });

  final String viewId;

  @override
  State<MobileNewPropertyScreen> createState() =>
      _MobileNewPropertyScreenState();
}

class _MobileNewPropertyScreenState extends State<MobileNewPropertyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FlowyText(
          LocaleKeys.grid_field_newProperty.tr(),
          fontSize: 16.0,
        ),
        leading: AppBarCancelButton(
          onTap: () => context.pop(),
        ),
        leadingWidth: 120,
        actions: [
          _SaveButton(onSave: () {}),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.only(
          top: 16.0,
        ),
        child: NewFieldOption(
          type: FieldType.RichText,
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.onSave,
  });

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Align(
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: onSave,
          child: FlowyText(
            LocaleKeys.button_save.tr(),
            color: const Color(0xFF00ADDC),
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }
}
