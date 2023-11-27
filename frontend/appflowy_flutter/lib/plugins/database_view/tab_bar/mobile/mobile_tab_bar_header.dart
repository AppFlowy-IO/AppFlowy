import 'package:appflowy/plugins/database_view/application/tab_bar_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/mobile_database_settings_button.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileTabBarHeader extends StatelessWidget {
  const MobileTabBarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DatabaseTabBarBloc, DatabaseTabBarState>(
      builder: (context, state) {
        final currentView = state.tabBars.firstWhereIndexedOrNull(
          (index, tabBar) => index == state.selectedIndex,
        );

        if (currentView == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      currentView.view.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  MobileDatabaseSettingsButton(
                    controller: state
                        .tabBarControllerByViewId[currentView.viewId]!
                        .controller,
                    toggleExtension: ToggleExtensionNotifier(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
          ],
        );
      },
    );
  }
}
