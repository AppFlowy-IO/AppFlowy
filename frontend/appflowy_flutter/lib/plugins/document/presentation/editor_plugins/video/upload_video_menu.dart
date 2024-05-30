import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide ColorOption;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class UploadVideoMenu extends StatefulWidget {
  const UploadVideoMenu({
    super.key,
    required this.onUrlSubmitted,
    this.onSelectedColor,
  });

  final void Function(String url) onUrlSubmitted;
  final void Function(String color)? onSelectedColor;

  @override
  State<UploadVideoMenu> createState() => _UploadVideoMenuState();
}

class _UploadVideoMenuState extends State<UploadVideoMenu> {
  @override
  Widget build(BuildContext context) {
    final constraints =
        PlatformExtension.isMobile ? const BoxConstraints(minHeight: 92) : null;

    return Container(
      padding: const EdgeInsets.all(8.0),
      constraints: constraints,
      child: _EmbedUrl(onSubmit: widget.onUrlSubmitted),
    );
  }
}

class _EmbedUrl extends StatefulWidget {
  const _EmbedUrl({required this.onSubmit});

  final void Function(String url) onSubmit;

  @override
  State<_EmbedUrl> createState() => _EmbedUrlState();
}

class _EmbedUrlState extends State<_EmbedUrl> {
  bool isUrlValid = true;
  String inputText = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlowyTextField(
          hintText: LocaleKeys.document_plugins_video_placeholder.tr(),
          onChanged: (value) => inputText = value,
          onEditingComplete: submit,
        ),
        if (!isUrlValid) ...[
          const VSpace(8),
          FlowyText(
            LocaleKeys.document_plugins_video_invalidVideoUrl.tr(),
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
              LocaleKeys.document_plugins_video_insertVideo.tr(),
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

  bool checkUrlValidity(String url) => videoUrlRegex.hasMatch(url);
}
