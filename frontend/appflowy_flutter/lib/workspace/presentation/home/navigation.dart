import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

typedef NaviAction = void Function();

class NavigationNotifier with ChangeNotifier {
  List<NavigationItem> navigationItems;
  NavigationNotifier({required this.navigationItems});

  void update(final HomeStackNotifier notifier) {
    bool shouldNotify = false;
    if (navigationItems != notifier.plugin.display.navigationItems) {
      navigationItems = notifier.plugin.display.navigationItems;
      shouldNotify = true;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }
}

class FlowyNavigation extends StatelessWidget {
  const FlowyNavigation({final Key? key}) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return ChangeNotifierProxyProvider<HomeStackNotifier, NavigationNotifier>(
      create: (final _) {
        final notifier = Provider.of<HomeStackNotifier>(context, listen: false);
        return NavigationNotifier(
          navigationItems: notifier.plugin.display.navigationItems,
        );
      },
      update: (final _, final notifier, final controller) =>
          controller!..update(notifier),
      child: Expanded(
        child: Row(
          children: [
            _renderCollapse(context),
            Selector<NavigationNotifier, List<NavigationItem>>(
              selector: (final context, final notifier) =>
                  notifier.navigationItems,
              builder: (final ctx, final items, final child) => Expanded(
                child: Row(
                  children: _renderNavigationItems(items),
                  // crossAxisAlignment: WrapCrossAlignment.start,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderCollapse(final BuildContext context) {
    return BlocBuilder<HomeSettingBloc, HomeSettingState>(
      buildWhen: (final p, final c) => p.isMenuCollapsed != c.isMenuCollapsed,
      builder: (final context, final state) {
        if (state.isMenuCollapsed) {
          return RotationTransition(
            turns: const AlwaysStoppedAnimation(180 / 360),
            child: Tooltip(
              richMessage: sidebarTooltipTextSpan(
                context,
                LocaleKeys.sideBar_openSidebar.tr(),
              ),
              child: FlowyIconButton(
                width: 24,
                hoverColor: Colors.transparent,
                onPressed: () {
                  context
                      .read<HomeSettingBloc>()
                      .add(const HomeSettingEvent.collapseMenu());
                },
                iconPadding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
                icon: svgWidget(
                  "home/hide_menu",
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }

  List<Widget> _renderNavigationItems(final List<NavigationItem> items) {
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

  List<NavigationItem> _filter(final List<NavigationItem> items) {
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
  final NavigationItem item;
  const NaviItemWidget(this.item, {final Key? key}) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return Expanded(
      child: item.leftBarItem.padding(horizontal: 2, vertical: 2),
    );
  }
}

class NaviItemDivider extends StatelessWidget {
  final Widget child;
  const NaviItemDivider({final Key? key, required this.child})
      : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: [child, const Text('/')],
    );
  }
}

class EllipsisNaviItem extends NavigationItem {
  final List<NavigationItem> items;
  EllipsisNaviItem({
    required this.items,
  });

  @override
  Widget get leftBarItem => FlowyText.medium(
        '...',
        fontSize: FontSizes.s16,
      );

  @override
  NavigationCallback get action => (final id) {};
}

TextSpan sidebarTooltipTextSpan(
  final BuildContext context,
  final String hintText,
) =>
    TextSpan(
      children: [
        TextSpan(
          text: "$hintText\n",
        ),
        TextSpan(
          text: Platform.isMacOS ? "⌘+\\" : "Ctrl+\\",
        ),
      ],
    );
