import 'dart:ui';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final PropertyValueNotifier<ViewLayoutPB?> createNewPageNotifier =
    PropertyValueNotifier(null);

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
    icon: FlowySvg(FlowySvgs.m_home_notification_m),
    activeIcon: FlowySvg(
      FlowySvgs.m_home_notification_m,
    ),
  ),
];

/// Builds the "shell" for the app by building a Scaffold with a
/// BottomNavigationBar, where [child] is placed in the body of the Scaffold.
class MobileBottomNavigationBar extends StatelessWidget {
  /// Constructs an [MobileBottomNavigationBar].
  const MobileBottomNavigationBar({
    required this.navigationShell,
    super.key,
  });

  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).isLightMode;
    final backgroundColor = isLightMode
        ? Colors.white.withOpacity(0.95)
        : const Color(0xFF23262B).withOpacity(0.95);
    return Scaffold(
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 3,
            sigmaY: 3,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: isLightMode
                  ? Border(
                      top: BorderSide(color: Theme.of(context).dividerColor),
                    )
                  : null,
              color: backgroundColor,
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
      ),
    );
  }

  /// Navigate to the current location of the branch at the provided index when
  /// tapping an item in the BottomNavigationBar.
  void _onTap(BuildContext context, int bottomBarIndex) {
    if (_items[bottomBarIndex].label == _addLabel) {
      // show an add dialog
      createNewPageNotifier.value = ViewLayoutPB.Document;
      return;
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
