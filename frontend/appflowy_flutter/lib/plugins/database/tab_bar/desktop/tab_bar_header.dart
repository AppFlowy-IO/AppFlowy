import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/tab_bar_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/widgets/dialog_v2.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'tab_bar_add_button.dart';

class TabBarHeader extends StatelessWidget {
  const TabBarHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Divider(
              color: AFThemeExtension.of(context).borderColor,
              height: 1,
              thickness: 1,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: DatabaseTabBar(),
              ),
              Flexible(
                child: BlocBuilder<DatabaseTabBarBloc, DatabaseTabBarState>(
                  builder: (context, state) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: pageSettingBarFromState(context, state),
                    );
                  },
                ),
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
        return ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: state.tabBars.length + 1,
          itemBuilder: (context, index) => index == state.tabBars.length
              ? AddDatabaseViewButton(
                  onTap: (layoutType) {
                    context
                        .read<DatabaseTabBarBloc>()
                        .add(DatabaseTabBarEvent.createView(layoutType, null));
                  },
                )
              : DatabaseTabBarItem(
                  key: ValueKey(state.tabBars[index].viewId),
                  view: state.tabBars[index].view,
                  isSelected: state.selectedIndex == index,
                  onTap: (selectedView) {
                    context
                        .read<DatabaseTabBarBloc>()
                        .add(DatabaseTabBarEvent.selectView(selectedView.id));
                  },
                ),
          separatorBuilder: (context, index) => VerticalDivider(
            width: 1.0,
            thickness: 1.0,
            indent: 8,
            endIndent: 13,
            color: Theme.of(context).dividerColor,
          ),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: SizedBox(
              height: 26,
              child: TabBarItemButton(
                view: view,
                isSelected: isSelected,
                onTap: () => onTap(view),
              ),
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

class TabBarItemButton extends StatefulWidget {
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
  State<TabBarItemButton> createState() => _TabBarItemButtonState();
}

class _TabBarItemButtonState extends State<TabBarItemButton> {
  final menuController = PopoverController();
  final iconController = PopoverController();

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (!widget.isSelected) {
      color = Theme.of(context).hintColor;
    }
    if (Theme.of(context).brightness == Brightness.dark) {
      color = null;
    }
    return AppFlowyPopover(
      controller: menuController,
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 460,
        maxHeight: 300,
      ),
      direction: PopoverDirection.bottomWithCenterAligned,
      clickHandler: PopoverClickHandler.gestureDetector,
      popupBuilder: (_) {
        return IntrinsicHeight(
          child: IntrinsicWidth(
            child: Column(
              children: [
                ActionCellWidget(
                  action: TabBarViewAction.rename,
                  itemHeight: ActionListSizes.itemHeight,
                  onSelected: (action) {
                    showAFTextFieldDialog(
                      context: context,
                      title: LocaleKeys.menuAppHeader_renameDialog.tr(),
                      initialValue: widget.view.nameOrDefault,
                      onConfirm: (newValue) {
                        context.read<DatabaseTabBarBloc>().add(
                              DatabaseTabBarEvent.renameView(
                                widget.view.id,
                                newValue,
                              ),
                            );
                      },
                    );
                    menuController.close();
                  },
                ),
                AppFlowyPopover(
                  controller: iconController,
                  direction: PopoverDirection.rightWithCenterAligned,
                  constraints: BoxConstraints.loose(const Size(364, 356)),
                  margin: const EdgeInsets.all(0),
                  child: ActionCellWidget(
                    action: TabBarViewAction.changeIcon,
                    itemHeight: ActionListSizes.itemHeight,
                    onSelected: (action) {
                      iconController.show();
                    },
                  ),
                  popupBuilder: (context) {
                    return FlowyIconEmojiPicker(
                      tabs: const [PickerTabType.icon],
                      enableBackgroundColorSelection: false,
                      onSelectedEmoji: (r) {
                        ViewBackendService.updateViewIcon(
                          view: widget.view,
                          viewIcon: r.data,
                        );
                        if (!r.keepOpen) {
                          iconController.close();
                          menuController.close();
                        }
                      },
                    );
                  },
                ),
                ActionCellWidget(
                  action: TabBarViewAction.delete,
                  itemHeight: ActionListSizes.itemHeight,
                  onSelected: (action) {
                    NavigatorAlertDialog(
                      title: LocaleKeys.grid_deleteView.tr(),
                      confirm: () {
                        context.read<DatabaseTabBarBloc>().add(
                              DatabaseTabBarEvent.deleteView(widget.view.id),
                            );
                      },
                    ).show(context);
                    menuController.close();
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: IntrinsicWidth(
        child: FlowyTooltip(
          message: widget.view.nameOrDefault,
          preferBelow: false,
          child: FlowyButton(
            radius: Corners.s6Border,
            hoverColor: AFThemeExtension.of(context).greyHover,
            onTap: () {
              if (widget.isSelected) menuController.show();
              widget.onTap.call();
            },
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            onSecondaryTap: () {
              menuController.show();
            },
            leftIcon: _buildViewIcon(),
            text: FlowyText(
              widget.view.nameOrDefault,
              lineHeight: 1.0,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              color: color,
              fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewIcon() {
    final iconData = widget.view.icon.toEmojiIconData();
    Widget icon;
    if (iconData.isEmpty || iconData.type != FlowyIconType.icon) {
      icon = widget.view.defaultIcon();
    } else {
      icon = RawEmojiIconWidget(
        emoji: iconData,
        emojiSize: 14.0,
        enableColor: false,
      );
    }
    final isReference =
        Provider.of<ReferenceState?>(context)?.isReference ?? false;
    final iconWidget = Opacity(opacity: 0.6, child: icon);
    return isReference
        ? Stack(
            children: [
              iconWidget,
              const Positioned(
                right: 0,
                bottom: 0,
                child: FlowySvg(
                  FlowySvgs.referenced_page_s,
                  blendMode: BlendMode.dstIn,
                ),
              ),
            ],
          )
        : iconWidget;
  }
}

enum TabBarViewAction implements ActionCell {
  rename,
  changeIcon,
  delete;

  @override
  String get name {
    switch (this) {
      case TabBarViewAction.rename:
        return LocaleKeys.disclosureAction_rename.tr();
      case TabBarViewAction.changeIcon:
        return LocaleKeys.disclosureAction_changeIcon.tr();
      case TabBarViewAction.delete:
        return LocaleKeys.disclosureAction_delete.tr();
    }
  }

  Widget icon(Color iconColor) {
    switch (this) {
      case TabBarViewAction.rename:
        return const FlowySvg(FlowySvgs.edit_s);
      case TabBarViewAction.changeIcon:
        return const FlowySvg(FlowySvgs.change_icon_s);
      case TabBarViewAction.delete:
        return const FlowySvg(FlowySvgs.delete_s);
    }
  }

  @override
  Widget? leftIcon(Color iconColor) => icon(iconColor);

  @override
  Widget? rightIcon(Color iconColor) => null;

  @override
  Color? textColor(BuildContext context) {
    return null;
  }
}
