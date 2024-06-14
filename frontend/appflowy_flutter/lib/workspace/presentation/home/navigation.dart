import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

class NavigationNotifier with ChangeNotifier {
  NavigationNotifier({required this.navigationItems});

  List<NavigationItem> navigationItems;

  void update(PageNotifier notifier) {
    if (navigationItems != notifier.plugin.widgetBuilder.navigationItems) {
      navigationItems = notifier.plugin.widgetBuilder.navigationItems;
      notifyListeners();
    }
  }
}

class FlowyNavigation extends StatelessWidget {
  const FlowyNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProxyProvider<PageNotifier, NavigationNotifier>(
      create: (_) {
        final notifier = Provider.of<PageNotifier>(context, listen: false);
        return NavigationNotifier(
          navigationItems: notifier.plugin.widgetBuilder.navigationItems,
        );
      },
      update: (_, notifier, controller) => controller!..update(notifier),
      child: Expanded(
        child: Row(
          children: [
            _renderCollapse(context),
            Selector<NavigationNotifier, List<NavigationItem>>(
              selector: (context, notifier) => notifier.navigationItems,
              builder: (ctx, items, child) => Expanded(
                child: Row(
                  children: _renderNavigationItems(items),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderCollapse(BuildContext context) {
    return BlocBuilder<HomeSettingBloc, HomeSettingState>(
      buildWhen: (p, c) => p.isMenuCollapsed != c.isMenuCollapsed,
      builder: (context, state) {
        if (!PlatformExtension.isWindows && state.isMenuCollapsed) {
          final color =
              Theme.of(context).isLightMode ? Colors.white : Colors.black;
          final textSpan = TextSpan(
            children: [
              TextSpan(
                text: '${LocaleKeys.sideBar_openSidebar.tr()}\n',
                style: Theme.of(context)
                    .tooltipTheme
                    .textStyle!
                    .copyWith(color: color),
              ),
              TextSpan(
                text: Platform.isMacOS ? '⌘+.' : 'Ctrl+\\',
                style: Theme.of(context)
                    .tooltipTheme
                    .textStyle!
                    .copyWith(color: Theme.of(context).hintColor),
              ),
            ],
          );
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: RotationTransition(
              turns: const AlwaysStoppedAnimation(180 / 360),
              child: FlowyTooltip(
                richMessage: textSpan,
                child: Listener(
                  onPointerDown: (event) => context
                      .read<HomeSettingBloc>()
                      .add(const HomeSettingEvent.collapseMenu()),
                  child: FlowyIconButton(
                    width: 24,
                    onPressed: () {},
                    iconPadding: const EdgeInsets.all(4),
                    icon: const FlowySvg(FlowySvgs.hide_menu_s),
                  ),
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  List<Widget> _renderNavigationItems(List<NavigationItem> items) {
    if (items.isEmpty) {
      return [];
    }

    final List<NavigationItem> newItems = _filter(items);
    final Widget last = NaviItemWidget(newItems.removeLast());

    final List<Widget> widgets = List.empty(growable: true);
    // widgets.addAll(newItems.map((item) => NaviItemDivider(child: NaviItemWidget(item))).toList());

    for (final item in newItems) {
      widgets.add(NaviItemWidget(item));
      widgets.add(const Text('/'));
    }

    widgets.add(last);

    return widgets;
  }

  List<NavigationItem> _filter(List<NavigationItem> items) {
    final length = items.length;
    if (length > 4) {
      final first = items[0];
      final ellipsisItems = items.getRange(1, length - 2).toList();
      final last = items.getRange(length - 2, length).toList();
      return [
        first,
        EllipsisNaviItem(items: ellipsisItems),
        ...last,
      ];
    } else {
      return items;
    }
  }
}

class NaviItemWidget extends StatelessWidget {
  const NaviItemWidget(this.item, {super.key});

  final NavigationItem item;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: item.leftBarItem.padding(horizontal: 2, vertical: 2),
    );
  }
}

class EllipsisNaviItem extends NavigationItem {
  EllipsisNaviItem({required this.items});

  final List<NavigationItem> items;

  @override
  Widget get leftBarItem => FlowyText.medium(
        '...',
        fontSize: FontSizes.s16,
      );

  @override
  Widget tabBarItem(String pluginId) => leftBarItem;

  @override
  NavigationCallback get action => (id) {};
}

TextSpan sidebarTooltipTextSpan(BuildContext context, String hintText) =>
    TextSpan(
      children: [
        TextSpan(
          text: "$hintText\n",
        ),
        TextSpan(
          text: Platform.isMacOS ? "⌘+." : "Ctrl+\\",
        ),
      ],
    );
