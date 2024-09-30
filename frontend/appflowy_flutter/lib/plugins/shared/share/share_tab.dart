import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/shared/share/share_bloc.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'constants.dart';

class ShareTab extends StatelessWidget {
  const ShareTab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        VSpace(18),
        _ShareTabHeader(),
        VSpace(2),
        _ShareTabDescription(),
        VSpace(14),
        _ShareTabContent(),
      ],
    );
  }
}

class _ShareTabHeader extends StatelessWidget {
  const _ShareTabHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const FlowySvg(FlowySvgs.share_tab_icon_s),
        const HSpace(6),
        FlowyText.medium(
          LocaleKeys.shareAction_shareTabTitle.tr(),
          figmaLineHeight: 18.0,
        ),
      ],
    );
  }
}

class _ShareTabDescription extends StatelessWidget {
  const _ShareTabDescription();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: FlowyText.regular(
        LocaleKeys.shareAction_shareTabDescription.tr(),
        fontSize: 13.0,
        figmaLineHeight: 18.0,
        color: Theme.of(context).hintColor,
      ),
    );
  }
}

class _ShareTabContent extends StatelessWidget {
  const _ShareTabContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShareBloc, ShareState>(
      builder: (context, state) {
        final shareUrl = _buildShareUrl(state);
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: FlowyTextField(
                  text: shareUrl, // todo: add workspace id + view id
                  readOnly: true,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const HSpace(8.0),
            PrimaryRoundedButton(
              margin: const EdgeInsets.symmetric(
                vertical: 9.0,
                horizontal: 14.0,
              ),
              text: LocaleKeys.button_copyLink.tr(),
              figmaLineHeight: 18.0,
              leftIcon: FlowySvg(
                FlowySvgs.share_tab_copy_s,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onTap: () => _copy(context, shareUrl),
            ),
          ],
        );
      },
    );
  }

  String _buildShareUrl(ShareState state) {
    return '${ShareConstants.shareBaseUrl}/${state.workspaceId}/${state.viewId}';
  }

  void _copy(BuildContext context, String url) {
    getIt<ClipboardService>().setData(
      ClipboardServiceData(plainText: url),
    );

    showToastNotification(
      context,
      message: LocaleKeys.grid_url_copy.tr(),
    );
  }
}
