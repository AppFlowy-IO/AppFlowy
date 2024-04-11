import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/tab_bar_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'tab_bar_add_button.dart';

class TabBarHeader extends StatelessWidget {
  const TabBarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: EdgeInsets.symmetric(
        horizontal: GridSize.horizontalHeaderPadding,
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Divider(
              color: Theme.of(context).dividerColor,
              height: 1,
              thickness: 1,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Flexible(child: DatabaseTabBar()),
              BlocBuilder<DatabaseTabBarBloc, DatabaseTabBarState>(
                builder: (context, state) {
                  return SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        const VSpace(3),
                        pageSettingBarFromState(context, state),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget pageSettingBarFromState(
    BuildContext context,
    DatabaseTabBarState state,
  ) {
    if (state.tabBars.length < state.selectedIndex) {
      return const SizedBox.shrink();
    }
    final tabBar = state.tabBars[state.selectedIndex];
    final controller =
        state.tabBarControllerByViewId[tabBar.viewId]!.controller;
    return tabBar.builder.settingBar(context, controller);
  }
}

class DatabaseTabBar extends StatefulWidget {
  const DatabaseTabBar({super.key});

  @override
  State<DatabaseTabBar> createState() => _DatabaseTabBarState();
}

class _DatabaseTabBarState extends State<DatabaseTabBar> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DatabaseTabBarBloc, DatabaseTabBarState>(
      builder: (context, state) {
        final children = state.tabBars.indexed.map((indexed) {
          final isSelected = state.selectedIndex == indexed.$1;
          final tabBar = indexed.$2;
          return DatabaseTabBarItem(
            key: ValueKey(tabBar.viewId),
            view: tabBar.view,
            isSelected: isSelected,
            onTap: (selectedView) {
              context.read<DatabaseTabBarBloc>().add(
                    DatabaseTabBarEvent.selectView(selectedView.id),
                  );
            },
          );
        }).toList();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: ListView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                children: children,
              ),
            ),
            AddDatabaseViewButton(
              onTap: (layoutType) async {
                context.read<DatabaseTabBarBloc>().add(
                      DatabaseTabBarEvent.createView(layoutType, null),
                    );
              },
            ),
          ],
        );
      },
    );
  }
}

class DatabaseTabBarItem extends StatelessWidget {
  const DatabaseTabBarItem({
    super.key,
    required this.view,
    required this.isSelected,
    required this.onTap,
  });

  final ViewPB view;
  final bool isSelected;
  final Function(ViewPB) onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Stack(
        children: [
          SizedBox(
            height: 26,
            child: TabBarItemButton(
              view: view,
              isSelected: isSelected,
              onTap: () => onTap(view),
            ),
          ),
          if (isSelected)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Divider(
                height: 2,
                thickness: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class TabBarItemButton extends StatelessWidget {
  const TabBarItemButton({
    super.key,
    required this.view,
    required this.isSelected,
    required this.onTap,
  });

  final ViewPB view;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<TabBarViewAction>(
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: TabBarViewAction.values,
      buildChild: (controller) {
        Color? color;
        if (!isSelected) {
          color = Theme.of(context).hintColor;
        }
        if (Theme.of(context).brightness == Brightness.dark) {
          color = null;
        }
        return IntrinsicWidth(
          child: FlowyButton(
            radius: Corners.s6Border,
            hoverColor: AFThemeExtension.of(context).greyHover,
            onTap: onTap,
            onSecondaryTap: () {
              controller.show();
            },
            leftIcon: FlowySvg(
              view.iconData,
              size: const Size(14, 14),
              color: color,
            ),
            text: FlowyText(
              view.name,
              fontSize: FontSizes.s11,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              color: color,
              fontWeight: isSelected ? null : FontWeight.w400,
            ),
          ),
        );
      },
      onSelected: (action, controller) {
        switch (action) {
          case TabBarViewAction.rename:
            NavigatorTextFieldDialog(
              title: LocaleKeys.menuAppHeader_renameDialog.tr(),
              value: view.name,
              onConfirm: (newValue, _) {
                context.read<DatabaseTabBarBloc>().add(
                      DatabaseTabBarEvent.renameView(view.id, newValue),
                    );
              },
            ).show(context);
            break;
          case TabBarViewAction.delete:
            NavigatorAlertDialog(
              title: LocaleKeys.grid_deleteView.tr(),
              confirm: () {
                context.read<DatabaseTabBarBloc>().add(
                      DatabaseTabBarEvent.deleteView(view.id),
                    );
              },
            ).show(context);

            break;
        }
        controller.close();
      },
    );
  }
}

enum TabBarViewAction implements ActionCell {
  rename,
  delete;

  @override
  String get name {
    switch (this) {
      case TabBarViewAction.rename:
        return LocaleKeys.disclosureAction_rename.tr();
      case TabBarViewAction.delete:
        return LocaleKeys.disclosureAction_delete.tr();
    }
  }

  Widget icon(Color iconColor) {
    switch (this) {
      case TabBarViewAction.rename:
        return const FlowySvg(FlowySvgs.edit_s);
      case TabBarViewAction.delete:
        return const FlowySvg(FlowySvgs.delete_s);
    }
  }

  @override
  Widget? leftIcon(Color iconColor) => icon(iconColor);

  @override
  Widget? rightIcon(Color iconColor) => null;
}
