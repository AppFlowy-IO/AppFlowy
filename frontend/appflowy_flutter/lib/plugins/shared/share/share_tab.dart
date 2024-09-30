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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const VSpace(18),
        const _ShareTabHeader(),
        const VSpace(2),
        FlowyText.regular(
          'For easy collaboration with anyone',
          fontSize: 13.0,
          figmaLineHeight: 18.0,
          color: Theme.of(context).hintColor,
        ),
        const VSpace(14),
        const _ShareTabContent(),
      ],
    );
  }
}

class _ShareTabHeader extends StatelessWidget {
  const _ShareTabHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        FlowySvg(FlowySvgs.share_tab_icon_s),
        HSpace(6),
        FlowyText.medium(
          'Invite to collaborate',
          figmaLineHeight: 18.0,
        ),
      ],
    );
  }
}

class _ShareTabContent extends StatelessWidget {
  const _ShareTabContent();

  @override
  Widget build(BuildContext context) {
    final shareUrl = _buildShareUrl(context);

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
          text: LocaleKeys.shareAction_buttonText.tr(),
          figmaLineHeight: 18.0,
          leftIcon: FlowySvg(
            FlowySvgs.m_toolbar_link_m,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          onTap: () => _copy(context, shareUrl),
        ),
      ],
    );
  }

  String _buildShareUrl(
    BuildContext context,
  ) {
    final workspaceId = context.read<ShareBloc>().state.workspaceId;
    final viewId = context.read<ShareBloc>().state.viewId;

    return '${ShareConstants.shareBaseUrl}/$workspaceId/$viewId';
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
