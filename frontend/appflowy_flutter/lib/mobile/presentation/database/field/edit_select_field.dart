import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

// include single select and multiple select
class EditSelectField extends StatefulWidget {
  const EditSelectField({super.key});

  @override
  State<EditSelectField> createState() => _EditSelectFieldState();
}

class _EditSelectFieldState extends State<EditSelectField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchField(
          hintText: LocaleKeys.grid_selectOption_searchOrCreateOption.tr(),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.hintText,
  });

  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: SizedBox(
        height: 44, // the height is fixed.
        child: FlowyTextField(
          hintText: hintText,
        ),
      ),
    );
  }
}
