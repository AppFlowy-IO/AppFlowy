import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    final style = Theme.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          enableFeedback: false,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              label: 'home',
              icon: FlowySvg(FlowySvgs.m_home_unselected_m),
              activeIcon:
                  FlowySvg(FlowySvgs.m_home_selected_m, blendMode: null),
            ),
            const BottomNavigationBarItem(
              label: 'add',
              icon: FlowySvg(FlowySvgs.m_home_add_m),
            ),
            BottomNavigationBarItem(
              label: 'notification',
              icon: const FlowySvg(FlowySvgs.m_home_notification_m),
              activeIcon: FlowySvg(
                FlowySvgs.m_home_notification_m,
                color: style.colorScheme.primary,
              ),
            ),
          ],
          currentIndex: navigationShell.currentIndex,
          onTap: (int bottomBarIndex) => _onTap(context, bottomBarIndex),
        ),
      ),
    );
  }

  /// Navigate to the current location of the branch at the provided index when
  /// tapping an item in the BottomNavigationBar.
  void _onTap(BuildContext context, int bottomBarIndex) {
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
