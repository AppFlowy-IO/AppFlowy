import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/settings_popup_menu.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileNotificationPageHeader extends StatelessWidget {
  const MobileNotificationPageHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HSpace(16.0),
          FlowyText(
            LocaleKeys.settings_notifications_titles_notifications.tr(),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          const Spacer(),
          const NotificationSettingsPopupMenu(),
          const HSpace(16.0),
        ],
      ),
    );
  }
}

class MobileNotificationMultiSelectPageHeader extends StatelessWidget {
  const MobileNotificationMultiSelectPageHeader({
    super.key,
    required this.selectedCount,
  });

  final ValueNotifier<int> selectedCount;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCancelButton(
            isOpaque: false,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () => bottomNavigationBarType.value =
                BottomNavigationBarActionType.home,
          ),
          ValueListenableBuilder(
            valueListenable: selectedCount,
            builder: (context, value, child) {
              return FlowyText(
                '$value Selected',
                fontSize: 17.0,
                figmaLineHeight: 24.0,
                fontWeight: FontWeight.w500,
              );
            },
          ),
          // this button is used to align the text to the center
          _buildCancelButton(
            isOpaque: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
      ),
    );
  }

  //
  Widget _buildCancelButton({
    required bool isOpaque,
    required EdgeInsets padding,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: FlowyText(
          LocaleKeys.button_cancel.tr(),
          fontSize: 17.0,
          figmaLineHeight: 24.0,
          fontWeight: FontWeight.w400,
          color: isOpaque ? Colors.transparent : null,
        ),
      ),
    );
  }
}
