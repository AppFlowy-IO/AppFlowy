import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/gesture.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class SyncErrorPage extends StatelessWidget {
  const SyncErrorPage({
    super.key,
    this.error,
  });

  final FlowyError? error;

  @override
  Widget build(BuildContext context) {
    return AnimatedGestureDetector(
      scaleFactor: 0.99,
      onTapUp: () {
        getIt<ClipboardService>().setPlainText(error.toString());
        showToastNotification(
          context,
          message: LocaleKeys.message_copy_success.tr(),
          bottomPadding: 0,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FlowySvg(
            FlowySvgs.icon_warning_xl,
            blendMode: null,
          ),
          const VSpace(16.0),
          FlowyText.medium(
            LocaleKeys.error_syncError.tr(),
            fontSize: 15,
          ),
          const VSpace(8.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FlowyText.regular(
              LocaleKeys.error_syncErrorHint.tr(),
              fontSize: 13,
              color: Theme.of(context).hintColor,
              textAlign: TextAlign.center,
              maxLines: 10,
            ),
          ),
          const VSpace(2.0),
          FlowyText.regular(
            '(${LocaleKeys.error_clickToCopy.tr()})',
            fontSize: 13,
            color: Theme.of(context).hintColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
