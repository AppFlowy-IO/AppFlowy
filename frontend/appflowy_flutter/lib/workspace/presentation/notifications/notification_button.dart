import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/notifications/notification_dialog.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key, required this.views});

  final List<ViewPB> views;

  @override
  Widget build(BuildContext context) {
    final mutex = PopoverMutex();

    return Tooltip(
      message: LocaleKeys.notificationHub_title.tr(),
      child: AppFlowyPopover(
        mutex: mutex,
        direction: PopoverDirection.bottomWithLeftAligned,
        constraints: const BoxConstraints(maxHeight: 250, maxWidth: 300),
        popupBuilder: (_) => NotificationDialog(views: views, mutex: mutex),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
