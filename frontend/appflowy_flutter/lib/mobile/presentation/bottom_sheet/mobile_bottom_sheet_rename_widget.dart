import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileBottomSheetRenameWidget extends StatefulWidget {
  const MobileBottomSheetRenameWidget({
    super.key,
    required this.name,
    required this.onRename,
  });

  final String name;
  final void Function(String name) onRename;

  @override
  State<MobileBottomSheetRenameWidget> createState() =>
      _MobileBottomSheetRenameWidgetState();
}

class _MobileBottomSheetRenameWidgetState
    extends State<MobileBottomSheetRenameWidget> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4.0,
        vertical: 16.0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HSpace(8.0),
          Expanded(
            child: SizedBox(
              height: 44.0,
              child: FlowyTextField(
                controller: controller,
              ),
            ),
          ),
          const HSpace(12.0),
          FlowyTextButton(
            LocaleKeys.button_edit.tr(),
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            fontColor: Colors.white,
            fillColor: Colors.lightBlue.shade300,
            onPressed: () {
              widget.onRename(controller.text);
            },
          ),
          const HSpace(8.0),
        ],
      ),
    );
  }
}
