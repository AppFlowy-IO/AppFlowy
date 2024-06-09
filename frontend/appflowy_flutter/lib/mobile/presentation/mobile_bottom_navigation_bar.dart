import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          items: _items,
          currentIndex: navigationShell.currentIndex,
          onTap: (int bottomBarIndex) => _onTap(context, bottomBarIndex),
        ),
      ),
    );
  }

  /// Navigate to the current location of the branch at the provided index when
  /// tapping an item in the BottomNavigationBar.
  void _onTap(BuildContext context, int bottomBarIndex) {
    if (_items[bottomBarIndex].label == _addLabel) {
      // show an add dialog
      _showCreatePageBottomSheet(context);
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

  void _showCreatePageBottomSheet(BuildContext context) {
    showMobileBottomSheet(
      context,
      showHeader: true,
      title: LocaleKeys.sideBar_addAPage.tr(),
      showDragHandle: true,
      showCloseButton: true,
      useRootNavigator: true,
      builder: (sheetContext) {
        return AddNewPageWidgetBottomSheet(
          view: ViewPB(),
          onAction: (layout) async {
            Navigator.of(sheetContext).pop();
            final currentWorkspaceId =
                await FolderEventReadCurrentWorkspace().send();
            await currentWorkspaceId.fold((s) async {
              final workspaceService = WorkspaceService(workspaceId: s.id);
              final result = await workspaceService.createView(
                name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
                viewSection: ViewSectionPB.Private,
                layout: layout,
              );
              result.fold((s) {
                context.pushView(s);
              }, (e) {
                Log.error('Failed to create new page: $e');
              });
            }, (e) {
              Log.error('Failed to read current workspace: $e');
            });
          },
        );
      },
    );
  }
}
