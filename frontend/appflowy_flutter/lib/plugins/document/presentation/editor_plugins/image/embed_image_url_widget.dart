import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

/// This pattern allows for both HTTP and HTTPS Scheme
/// It allows for query parameters
/// It only allows the following image extensions: .png, .jpg, .gif, .webm
///
const String _imgUrlPattern =
    r'(https?:\/\/)([^\s(["<,>/]*)(\/)[^\s[",><]*(.png|.jpg|.gif|.webm)(\?[^\s[",><]*)?';

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
        FlowyTextField(
          hintText: LocaleKeys.document_imageBlock_embedLink_placeholder.tr(),
          onChanged: (value) => inputText = value,
          onEditingComplete: submit,
        ),
        if (!isUrlValid) ...[
          const VSpace(8),
          FlowyText(
            LocaleKeys.document_plugins_cover_invalidImageUrl.tr(),
            color: Theme.of(context).colorScheme.error,
          ),
        ],
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
            onTap: submit,
          ),
        ),
      ],
    );
  }

  void submit() {
    if (checkUrlValidity(inputText)) {
      return widget.onSubmit(inputText);
    }

    setState(() => isUrlValid = false);
  }

  bool checkUrlValidity(String url) {
    final regex = RegExp(_imgUrlPattern);
    return regex.hasMatch(url);
  }
}
