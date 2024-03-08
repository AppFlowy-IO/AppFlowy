import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        BottomSheetHeader(
          title: LocaleKeys.editor_editLink.tr(),
          onClose: () => context.pop(),
          onDone: () {
            widget.onEdit(textController.text, hrefController.text);
          },
        ),
        const VSpace(20.0),
        _buildTextField(
          textController,
          LocaleKeys.document_inlineLink_title_placeholder.tr(),
        ),
        const VSpace(12.0),
        _buildTextField(
          hrefController,
          LocaleKeys.document_inlineLink_url_placeholder.tr(),
        ),
        const VSpace(12.0),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String? hintText,
  ) {
    return SizedBox(
      height: 48.0,
      child: FlowyTextField(
        controller: controller,
        hintText: hintText,
        textStyle: const TextStyle(fontSize: 16.0),
        hintStyle: const TextStyle(fontSize: 16.0),
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
