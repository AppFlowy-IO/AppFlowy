import 'dart:ui';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/notifications/mobile_notifications_screen.dart';
import 'package:appflowy/mobile/presentation/widgets/navigation_bar_button.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

enum BottomNavigationBarActionType {
  home,
  notificationMultiSelect,
}

final PropertyValueNotifier<ViewLayoutPB?> mobileCreateNewPageNotifier =
    PropertyValueNotifier(null);
final ValueNotifier<BottomNavigationBarActionType> bottomNavigationBarType =
    ValueNotifier(BottomNavigationBarActionType.home);

const _homeLabel = 'home';
const _addLabel = 'add';
const _notificationLabel = 'notification';
final _items = <BottomNavigationBarItem>[
  const BottomNavigationBarItem(
    label: _homeLabel,
    icon: FlowySvg(FlowySvgs.m_home_unselected_m),
    activeIcon: FlowySvg(FlowySvgs.m_home_selected_m, blendMode: null),
  ),
  const BottomNavigationBarItem(
    label: _addLabel,
    icon: FlowySvg(FlowySvgs.m_home_add_m),
  ),
  const BottomNavigationBarItem(
    label: _notificationLabel,
    icon: _NotificationNavigationBarItemIcon(),
    activeIcon: _NotificationNavigationBarItemIcon(
      isActive: true,
    ),
  ),
];

/// Builds the "shell" for the app by building a Scaffold with a
/// BottomNavigationBar, where [child] is placed in the body of the Scaffold.
class MobileBottomNavigationBar extends StatefulWidget {
  /// Constructs an [MobileBottomNavigationBar].
  const MobileBottomNavigationBar({
    required this.navigationShell,
    super.key,
  });

  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  @override
  State<MobileBottomNavigationBar> createState() =>
      _MobileBottomNavigationBarState();
}

class _MobileBottomNavigationBarState extends State<MobileBottomNavigationBar> {
  Widget? _bottomNavigationBar;

  @override
  void initState() {
    super.initState();

    bottomNavigationBarType.addListener(_animate);
  }

  @override
  void dispose() {
    bottomNavigationBarType.removeListener(_animate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bottomNavigationBar = switch (bottomNavigationBarType.value) {
      BottomNavigationBarActionType.home =>
        _buildHomePageNavigationBar(context),
      BottomNavigationBarActionType.notificationMultiSelect =>
        _buildNotificationNavigationBar(context),
    };

    return Scaffold(
      body: widget.navigationShell,
      extendBody: true,
      bottomNavigationBar: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: _transitionBuilder,
        child: _bottomNavigationBar,
      ),
    );
  }

  Widget _buildHomePageNavigationBar(BuildContext context) {
    return _HomePageNavigationBar(
      navigationShell: widget.navigationShell,
    );
  }

  Widget _buildNotificationNavigationBar(BuildContext context) {
    return const _NotificationNavigationBar();
  }

  // widget A going down, widget B going up
  Widget _transitionBuilder(
    Widget child,
    Animation<double> animation,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  void _animate() {
    setState(() {});
  }
}

class _NotificationNavigationBarItemIcon extends StatelessWidget {
  const _NotificationNavigationBarItemIcon({
    this.isActive = false,
  });

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<ReminderBloc>(),
      child: BlocBuilder<ReminderBloc, ReminderState>(
        builder: (context, state) {
          final hasUnreads = state.reminders.any(
            (reminder) => !reminder.isRead,
          );
          return Stack(
            children: [
              isActive
                  ? const FlowySvg(
                      FlowySvgs.m_home_active_notification_m,
                      blendMode: null,
                    )
                  : const FlowySvg(
                      FlowySvgs.m_home_notification_m,
                    ),
              if (hasUnreads)
                const Positioned(
                  top: 2,
                  right: 4,
                  child: _RedDot(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RedDot extends StatelessWidget {
  const _RedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: const Color(0xFFFF2214),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _HomePageNavigationBar extends StatelessWidget {
  const _HomePageNavigationBar({
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 3,
          sigmaY: 3,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: context.border,
            color: context.backgroundColor,
          ),
          child: BottomNavigationBar(
            showSelectedLabels: false,
            showUnselectedLabels: false,
            enableFeedback: false,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: _items,
            backgroundColor: Colors.transparent,
            currentIndex: navigationShell.currentIndex,
            onTap: (int bottomBarIndex) => _onTap(context, bottomBarIndex),
          ),
        ),
      ),
    );
  }

  /// Navigate to the current location of the branch at the provided index when
  /// tapping an item in the BottomNavigationBar.
  void _onTap(BuildContext context, int bottomBarIndex) {
    final label = _items[bottomBarIndex].label;
    if (label == _addLabel) {
      // show an add dialog
      mobileCreateNewPageNotifier.value = ViewLayoutPB.Document;
      return;
    } else if (label == _notificationLabel) {
      getIt<ReminderBloc>().add(const ReminderEvent.refresh());
    }
    // When navigating to a new branch, it's recommended to use the goBranch
    // method, as doing so makes sure the last navigation state of the
    // Navigator for the branch is restored.
    navigationShell.goBranch(
      bottomBarIndex,
      // A common pattern when using bottom navigation bars is to support
      // navigating to the initial location when tapping the item that is
      // already active. This example demonstrates how to support this behavior,
      // using the initialLocation parameter of goBranch.
      initialLocation: bottomBarIndex == navigationShell.currentIndex,
    );
  }
}

class _NotificationNavigationBar extends StatelessWidget {
  const _NotificationNavigationBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      // todo: use real height here.
      height: 90,
      decoration: BoxDecoration(
        border: context.border,
        color: context.backgroundColor,
      ),
      padding: const EdgeInsets.only(bottom: 20),
      child: ValueListenableBuilder(
        valueListenable: mSelectedNotificationIds,
        builder: (context, value, child) {
          if (value.isEmpty) {
            // not editable
            return IgnorePointer(
              child: Opacity(
                opacity: 0.3,
                child: child,
              ),
            );
          }

          return child!;
        },
        child: Row(
          children: [
            const HSpace(20),
            Expanded(
              child: NavigationBarButton(
                icon: FlowySvgs.m_notification_action_mark_as_read_s,
                text: LocaleKeys.settings_notifications_action_markAsRead.tr(),
                onTap: () => _onMarkAsRead(context),
              ),
            ),
            const HSpace(16),
            Expanded(
              child: NavigationBarButton(
                icon: FlowySvgs.m_notification_action_archive_s,
                text: LocaleKeys.settings_notifications_action_archive.tr(),
                onTap: () => _onArchive(context),
              ),
            ),
            const HSpace(20),
          ],
        ),
      ),
    );
  }

  void _onMarkAsRead(BuildContext context) {
    if (mSelectedNotificationIds.value.isEmpty) {
      return;
    }

    showToastNotification(
      context,
      message: LocaleKeys
          .settings_notifications_markAsReadNotifications_allSuccess
          .tr(),
    );

    getIt<ReminderBloc>()
        .add(ReminderEvent.markAsRead(mSelectedNotificationIds.value));

    mSelectedNotificationIds.value = [];
  }

  void _onArchive(BuildContext context) {
    if (mSelectedNotificationIds.value.isEmpty) {
      return;
    }

    showToastNotification(
      context,
      message: LocaleKeys.settings_notifications_archiveNotifications_allSuccess
          .tr(),
    );

    getIt<ReminderBloc>()
        .add(ReminderEvent.archive(mSelectedNotificationIds.value));

    mSelectedNotificationIds.value = [];
  }
}

extension on BuildContext {
  Color get backgroundColor {
    return Theme.of(this).isLightMode
        ? Colors.white.withOpacity(0.95)
        : const Color(0xFF23262B).withOpacity(0.95);
  }

  Color get borderColor {
    return Theme.of(this).isLightMode
        ? const Color(0x141F2329)
        : const Color(0xFF23262B).withOpacity(0.5);
  }

  Border? get border {
    return Theme.of(this).isLightMode
        ? Border(top: BorderSide(color: borderColor))
        : null;
  }
}
