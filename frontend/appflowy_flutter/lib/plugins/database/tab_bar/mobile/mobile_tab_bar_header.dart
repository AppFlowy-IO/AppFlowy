import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_transition_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/database/view/database_view_list.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/plugins/database/application/tab_bar_bloc.dart';
import 'package:appflowy/plugins/database/widgets/setting/mobile_database_controls.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../grid/presentation/grid_page.dart';

class MobileTabBarHeader extends StatefulWidget {
  const MobileTabBarHeader({super.key});

  @override
  State<MobileTabBarHeader> createState() => _MobileTabBarHeaderState();
}

class _MobileTabBarHeaderState extends State<MobileTabBarHeader> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: GridSize.horizontalHeaderPadding,
        top: 14.0,
        right: GridSize.horizontalHeaderPadding - 5.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _DatabaseViewSelectorButton(),
          const Spacer(),
          BlocBuilder<DatabaseTabBarBloc, DatabaseTabBarState>(
            builder: (context, state) {
              final currentView = state.tabBars.firstWhereIndexedOrNull(
                (index, tabBar) => index == state.selectedIndex,
              );

              if (currentView == null) {
                return const SizedBox.shrink();
              }

              return MobileDatabaseControls(
                controller: state
                    .tabBarControllerByViewId[currentView.viewId]!.controller,
                toggleExtension: ToggleExtensionNotifier(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DatabaseViewSelectorButton extends StatelessWidget {
  const _DatabaseViewSelectorButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DatabaseTabBarBloc, DatabaseTabBarState>(
      builder: (context, state) {
        final tabBar = state.tabBars.firstWhereIndexedOrNull(
          (index, tabBar) => index == state.selectedIndex,
        );

        if (tabBar == null) {
          return const SizedBox.shrink();
        }

        return TextButton(
          style: ButtonStyle(
            padding: const WidgetStatePropertyAll(
              EdgeInsets.fromLTRB(12, 8, 8, 8),
            ),
            maximumSize: const WidgetStatePropertyAll(Size(200, 48)),
            minimumSize: const WidgetStatePropertyAll(Size(48, 0)),
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            backgroundColor: WidgetStatePropertyAll(
              Theme.of(context).brightness == Brightness.light
                  ? const Color(0x0F212729)
                  : const Color(0x0FFFFFFF),
            ),
            overlayColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.secondary,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewIconButton(context, tabBar.view),
              const HSpace(6),
              Flexible(
                child: FlowyText.medium(
                  tabBar.view.name,
                  fontSize: 13,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const HSpace(8),
              const FlowySvg(
                FlowySvgs.arrow_tight_s,
                size: Size.square(10),
              ),
            ],
          ),
          onPressed: () {
            showTransitionMobileBottomSheet(
              context,
              showDivider: false,
              builder: (_) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider<ViewBloc>.value(
                      value: context.read<ViewBloc>(),
                    ),
                    BlocProvider<DatabaseTabBarBloc>.value(
                      value: context.read<DatabaseTabBarBloc>(),
                    ),
                  ],
                  child: const MobileDatabaseViewList(),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildViewIconButton(BuildContext context, ViewPB view) {
    return view.icon.value.isNotEmpty
        ? EmojiText(
            emoji: view.icon.value,
            fontSize: 16.0,
          )
        : SizedBox.square(
            dimension: 16.0,
            child: view.defaultIcon(),
          );
  }
}
