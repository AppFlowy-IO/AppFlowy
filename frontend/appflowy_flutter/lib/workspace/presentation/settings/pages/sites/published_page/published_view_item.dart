import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/navigator_context_exntesion.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/constants.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/publish_info_view_item.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/published_page/published_view_more_action.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
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
    final formattedDate = SettingsPageSitesConstants.dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(
        publishInfoView.info.publishTimestampSec.toInt() * 1000,
      ),
    );
    final flexes = SettingsPageSitesConstants.publishedViewItemFlexes;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Published page name
        Expanded(
          flex: flexes[0],
          child: PublishInfoViewItem(
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
          ),
        ),

        // Published Name
        Expanded(
          flex: flexes[1],
          child: Padding(
            padding: const EdgeInsets.only(right: 48.0),
            child: FlowyText(
              publishInfoView.info.publishName,
              fontSize: 14.0,
              figmaLineHeight: 18.0,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Published at
        Expanded(
          flex: flexes[2],
          child: FlowyText(
            formattedDate,
            fontSize: 14.0,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // More actions
        PublishedViewMoreAction(
          publishInfoView: publishInfoView,
        ),
      ],
    );
  }
}
