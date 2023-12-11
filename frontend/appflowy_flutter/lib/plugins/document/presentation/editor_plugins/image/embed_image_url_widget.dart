import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class EmbedImageUrlWidget extends StatefulWidget {
  const EmbedImageUrlWidget({
    super.key,
    required this.onSubmit,
  });

  final void Function(String url) onSubmit;

  @override
  State<EmbedImageUrlWidget> createState() => _EmbedImageUrlWidgetState();
}

class _EmbedImageUrlWidgetState extends State<EmbedImageUrlWidget> {
  String inputText = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FlowyTextField(
          autoFocus: true,
          hintText: LocaleKeys.document_imageBlock_embedLink_placeholder.tr(),
          onChanged: (value) => inputText = value,
          onEditingComplete: () => widget.onSubmit(inputText),
        ),
        const VSpace(8),
        SizedBox(
          width: 160,
          child: FlowyButton(
            showDefaultBoxDecorationOnMobile: true,
            margin: const EdgeInsets.all(8.0),
            text: FlowyText(
              LocaleKeys.document_imageBlock_embedLink_label.tr(),
              textAlign: TextAlign.center,
            ),
            onTap: () => widget.onSubmit(inputText),
          ),
        ),
      ],
    );
  }
}
