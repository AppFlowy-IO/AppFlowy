import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/constants.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class PublishedViewMoreAction extends StatelessWidget {
  const PublishedViewMoreAction({
    super.key,
    required this.publishInfoView,
  });

  final PublishInfoViewPB publishInfoView;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: const BoxConstraints(maxWidth: 168),
      offset: const Offset(6, 0),
      animationDuration: Durations.short3,
      beginScaleFactor: 1.0,
      beginOpacity: 0.8,
      child: const SizedBox(
        width: SettingsPageSitesConstants.threeDotsButtonWidth,
        child: FlowyButton(
          useIntrinsicWidth: true,
          text: FlowySvg(FlowySvgs.three_dots_s),
        ),
      ),
      popupBuilder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(context, type: _ActionType.viewSite),
            _buildActionButton(context, type: _ActionType.copySiteLink),
            _buildActionButton(context, type: _ActionType.settings),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required _ActionType type,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: FlowyIconTextButton(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        iconPadding: 10.0,
        onTap: () => _onTap(context, type),
        leftIconBuilder: (onHover) => FlowySvg(
          type.leftIconSvg,
        ),
        textBuilder: (onHover) => FlowyText.regular(
          type.name,
          fontSize: 14.0,
          figmaLineHeight: 18.0,
        ),
      ),
    );
  }

  void _onTap(BuildContext context, _ActionType type) {
    final url = ShareConstants.buildPublishUrl(
      nameSpace: publishInfoView.info.namespace,
      publishName: publishInfoView.info.publishName,
    );

    switch (type) {
      case _ActionType.viewSite:
        afLaunchUrlString(url);
        PopoverContainer.of(context).close();
        break;
      case _ActionType.copySiteLink:
        getIt<ClipboardService>().setData(
          ClipboardServiceData(plainText: url),
        );
        showToastNotification(
          context,
          message: LocaleKeys.grid_url_copy.tr(),
        );
        PopoverContainer.of(context).close();
        break;
      case _ActionType.settings:
        break;
    }
  }
}

enum _ActionType {
  viewSite,
  copySiteLink,
  settings;

  String get name => switch (this) {
        _ActionType.viewSite => LocaleKeys.shareAction_visitSite.tr(),
        _ActionType.copySiteLink => LocaleKeys.shareAction_copyLink.tr(),
        _ActionType.settings => LocaleKeys.settings_popupMenuItem_settings.tr(),
      };

  FlowySvgData get leftIconSvg => switch (this) {
        _ActionType.viewSite => FlowySvgs.share_publish_s,
        _ActionType.copySiteLink => FlowySvgs.copy_s,
        _ActionType.settings => FlowySvgs.settings_s,
      };
}
