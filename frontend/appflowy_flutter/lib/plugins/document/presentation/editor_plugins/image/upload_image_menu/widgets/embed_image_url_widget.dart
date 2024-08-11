import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

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
  bool isUrlValid = true;
  String inputText = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const VSpace(12),
        FlowyTextField(
          hintText: LocaleKeys.document_imageBlock_embedLink_placeholder.tr(),
          onChanged: (value) => inputText = value,
          onEditingComplete: submit,
        ),
        if (!isUrlValid) ...[
          const VSpace(12),
          FlowyText(
            LocaleKeys.document_plugins_cover_invalidImageUrl.tr(),
            color: Theme.of(context).colorScheme.error,
          ),
        ],
        const VSpace(20),
        SizedBox(
          height: 32,
          width: 300,
          child: FlowyButton(
            backgroundColor: Theme.of(context).colorScheme.primary,
            //TODO(Lucas): change the hover color to the color used for the Share button
            hoverColor: Theme.of(context).colorScheme.primary,
            showDefaultBoxDecorationOnMobile: true,
            margin: const EdgeInsets.all(5),
            text: FlowyText(
              LocaleKeys.document_imageBlock_embedLink_label.tr(),
              lineHeight: 1,
              textAlign: TextAlign.center,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onTap: submit,
          ),
        ),
        const VSpace(8),
      ],
    );
  }

  void submit() {
    if (checkUrlValidity(inputText)) {
      return widget.onSubmit(inputText);
    }

    setState(() => isUrlValid = false);
  }

  bool checkUrlValidity(String url) => imgUrlRegex.hasMatch(url);
}
