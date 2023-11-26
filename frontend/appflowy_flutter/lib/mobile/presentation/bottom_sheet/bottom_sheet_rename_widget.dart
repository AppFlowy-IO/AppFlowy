import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileBottomSheetRenameWidget extends StatefulWidget {
  const MobileBottomSheetRenameWidget({
    super.key,
    required this.name,
    required this.onRename,
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
  });

  final String name;
  final void Function(String name) onRename;
  final EdgeInsets padding;

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
      padding: widget.padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: SizedBox(
              height: 42.0,
              child: FlowyTextField(
                controller: controller,
              ),
            ),
          ),
          const HSpace(12.0),
          FlowyTextButton(
            LocaleKeys.button_edit.tr(),
            constraints: const BoxConstraints.tightFor(height: 42),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
            ),
            fontColor: Colors.white,
            fillColor: Theme.of(context).primaryColor,
            onPressed: () {
              widget.onRename(controller.text);
            },
          ),
        ],
      ),
    );
  }
}
