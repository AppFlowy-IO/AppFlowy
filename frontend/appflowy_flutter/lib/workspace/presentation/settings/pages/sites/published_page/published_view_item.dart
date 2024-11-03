import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/navigator_context_exntesion.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/constants.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/publish_info_view_item.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/published_page/published_view_more_action.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class PublishedViewItem extends StatelessWidget {
  const PublishedViewItem({
    super.key,
    required this.publishInfoView,
  });

  final PublishInfoViewPB publishInfoView;

  @override
  Widget build(BuildContext context) {
    final flexes = SettingsPageSitesConstants.publishedViewItemFlexes;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Published page name
        Expanded(
          flex: flexes[0],
          child: _buildPublishedPageName(context),
        ),

        // Published Name
        Expanded(
          flex: flexes[1],
          child: _buildPublishedName(context),
        ),

        // Published at
        Expanded(
          flex: flexes[2],
          child: _buildPublishedAt(context),
        ),

        // More actions
        PublishedViewMoreAction(
          publishInfoView: publishInfoView,
        ),
      ],
    );
  }

  Widget _buildPublishedPageName(BuildContext context) {
    return PublishInfoViewItem(
      extraTooltipMessage:
          LocaleKeys.settings_sites_publishedPage_clickToOpenPageInApp.tr(),
      publishInfoView: publishInfoView,
      onTap: () {
        context.popToHome();

        getIt<ActionNavigationBloc>().add(
          ActionNavigationEvent.performAction(
            action: NavigationAction(
              objectId: publishInfoView.view.viewId,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPublishedAt(BuildContext context) {
    final formattedDate = SettingsPageSitesConstants.dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(
        publishInfoView.info.publishTimestampSec.toInt() * 1000,
      ),
    );
    return FlowyText(
      formattedDate,
      fontSize: 14.0,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPublishedName(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(right: 48.0),
      child: FlowyButton(
        useIntrinsicWidth: true,
        onTap: () {
          final url = ShareConstants.buildPublishUrl(
            nameSpace: publishInfoView.info.namespace,
            publishName: publishInfoView.info.publishName,
          );
          afLaunchUrlString(url);
        },
        text: FlowyTooltip(
          message:
              '${LocaleKeys.settings_sites_publishedPage_clickToOpenPageInBrowser.tr()}\n${publishInfoView.info.publishName}',
          child: FlowyText(
            publishInfoView.info.publishName,
            fontSize: 14.0,
            figmaLineHeight: 18.0,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
