import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/theme_upload/theme_upload.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class ThemeUploadFailureWidget extends StatelessWidget {
  const ThemeUploadFailureWidget({super.key, required this.errorMessage});

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context)
          .colorScheme
          .error
          .withOpacity(ThemeUploadWidget.fadeOpacity),
      constraints: const BoxConstraints.expand(),
      padding: ThemeUploadWidget.padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          FlowySvg(
            FlowySvgs.close_m,
            size: ThemeUploadWidget.iconSize,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          FlowyText.medium(
            errorMessage,
            overflow: TextOverflow.ellipsis,
          ),
          ThemeUploadWidget.elementSpacer,
          const ThemeUploadLearnMoreButton(),
          ThemeUploadWidget.elementSpacer,
          ThemeUploadButton(color: Theme.of(context).colorScheme.error),
          ThemeUploadWidget.elementSpacer,
        ],
      ),
    );
  }
}
