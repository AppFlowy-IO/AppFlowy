import 'package:flutter/material.dart';

import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/notifications/notification_action.dart';
import 'package:appflowy/workspace/application/notifications/notification_action_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-search/entities.pb.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.result,
    required this.onSelected,
  });

  final SearchResultPB result;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final icon = result.icon.value.isNotEmpty
        ? EmojiText(
            emoji: result.icon.value,
            fontSize: 18.0,
          )
        : const SizedBox.shrink();

    return ListTile(
      title: Row(
        children: [
          icon,
          const HSpace(2),
          FlowyText(result.data),
        ],
      ),
      onTap: () {
        onSelected();

        // NotificationActionBloc can be renamed and made into
        // an overall ActionNavigationBloc or similar.
        getIt<NotificationActionBloc>().add(
          NotificationActionEvent.performAction(
            action: NotificationAction(objectId: result.viewId),
          ),
        );
      },
    );
  }
}
