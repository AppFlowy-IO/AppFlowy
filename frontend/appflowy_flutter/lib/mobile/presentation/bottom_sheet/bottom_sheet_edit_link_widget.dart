import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:string_validator/string_validator.dart';

class MobileBottomSheetEditLinkWidget extends StatefulWidget {
  const MobileBottomSheetEditLinkWidget({
    super.key,
    required this.text,
    required this.href,
    required this.onEdit,
  });

  final String text;
  final String? href;
  final void Function(String text, String href) onEdit;

  @override
  State<MobileBottomSheetEditLinkWidget> createState() =>
      _MobileBottomSheetEditLinkWidgetState();
}

class _MobileBottomSheetEditLinkWidgetState
    extends State<MobileBottomSheetEditLinkWidget> {
  late final TextEditingController textController;
  late final TextEditingController hrefController;

  @override
  void initState() {
    super.initState();

    textController = TextEditingController(
      text: widget.text,
    );
    hrefController = TextEditingController(
      text: widget.href,
    );
  }

  @override
  void dispose() {
    textController.dispose();
    hrefController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField(textController, null),
        const VSpace(12.0),
        _buildTextField(hrefController, LocaleKeys.editor_linkTextHint.tr()),
        const VSpace(12.0),
        Row(
          children: [
            Expanded(
              child: BottomSheetActionWidget(
                text: LocaleKeys.button_cancel.tr(),
                onTap: () => context.pop(),
              ),
            ),
            const HSpace(8),
            Expanded(
              child: BottomSheetActionWidget(
                text: LocaleKeys.button_done.tr(),
                onTap: () {
                  widget.onEdit(textController.text, hrefController.text);
                },
              ),
            ),
            if (widget.href != null && isURL(widget.href)) ...[
              const HSpace(8),
              Expanded(
                child: BottomSheetActionWidget(
                  text: LocaleKeys.editor_openLink.tr(),
                  onTap: () {
                    safeLaunchUrl(widget.href!);
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String? hintText,
  ) {
    return SizedBox(
      height: 44.0,
      child: FlowyTextField(
        controller: controller,
        hintText: hintText,
        suffixIcon: Padding(
          padding: const EdgeInsets.all(4.0),
          child: FlowyButton(
            text: const FlowySvg(
              FlowySvgs.close_lg,
            ),
            margin: EdgeInsets.zero,
            useIntrinsicWidth: true,
            onTap: () {
              controller.clear();
            },
          ),
        ),
      ),
    );
  }
}
