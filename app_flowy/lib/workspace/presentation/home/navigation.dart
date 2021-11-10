import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

typedef NaviAction = void Function();

class NavigationNotifier with ChangeNotifier {
  List<NavigationItem> navigationItems;
  PublishNotifier<bool> collapasedNotifier;
  NavigationNotifier({required this.navigationItems, required this.collapasedNotifier});

  void update(HomeStackNotifier notifier) {
    bool shouldNotify = false;
    if (navigationItems != notifier.context.navigationItems) {
      navigationItems = notifier.context.navigationItems;
      shouldNotify = true;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }
}

// [[diagram: HomeStack navigation flow]]
//                                                                              ┌───────────────────────┐
//                     2.notify listeners                                ┌──────│DefaultHomeStackContext│
//  ┌────────────────┐           ┌───────────┐   ┌────────────────┐      │      └───────────────────────┘
//  │HomeStackNotifie│◀──────────│ HomeStack │◀──│HomeStackContext│◀─ impl
//  └────────────────┘           └───────────┘   └────────────────┘      │       ┌───────────────────┐
//           │                         ▲                                 └───────│  DocStackContext  │
//           │                         │                                         └───────────────────┘
//    3.notify change            1.set context
//           │                         │
//           ▼                         │
// ┌───────────────────┐     ┌──────────────────┐
// │NavigationNotifier │     │ ViewSectionItem  │
// └───────────────────┘     └──────────────────┘
//           │
//           │
//           ▼
//  ┌─────────────────┐
//  │ FlowyNavigation │   4.render navigation items
//  └─────────────────┘
class FlowyNavigation extends StatelessWidget {
  const FlowyNavigation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProxyProvider<HomeStackNotifier, NavigationNotifier>(
      create: (_) {
        final notifier = Provider.of<HomeStackNotifier>(context, listen: false);
        return NavigationNotifier(
          navigationItems: notifier.context.navigationItems,
          collapasedNotifier: notifier.collapsedNotifier,
        );
      },
      update: (_, notifier, controller) => controller!..update(notifier),
      child: Row(children: [
        Selector<NavigationNotifier, PublishNotifier<bool>>(
            selector: (context, notifier) => notifier.collapasedNotifier,
            builder: (ctx, collapsedNotifier, child) => _renderCollapse(ctx, collapsedNotifier)),
        Selector<NavigationNotifier, List<NavigationItem>>(
            selector: (context, notifier) => notifier.navigationItems,
            builder: (ctx, items, child) => Row(children: _renderNavigationItems(items))),
      ]),
    );
  }

  Widget _renderCollapse(BuildContext context, PublishNotifier<bool> collapsedNotifier) {
    return ChangeNotifierProvider.value(
      value: collapsedNotifier,
      child: Consumer(
        builder: (ctx, PublishNotifier<bool> notifier, child) {
          if (notifier.currentValue ?? false) {
            return RotationTransition(
              turns: const AlwaysStoppedAnimation(180 / 360),
              child: FlowyIconButton(
                width: 24,
                onPressed: () {
                  notifier.value = false;
                },
                iconPadding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
                icon: svg("home/hide_menu"),
              ),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }

  List<Widget> _renderNavigationItems(List<NavigationItem> items) {
    if (items.isEmpty) {
      return [];
    }

    List<NavigationItem> newItems = _filter(items);
    Widget last = NaviItemWidget(newItems.removeLast());

    List<Widget> widgets = List.empty(growable: true);
    widgets.addAll(newItems.map((item) => NaviItemDivider(child: NaviItemWidget(item))).toList());
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

class IconNaviItemWidget extends StatelessWidget {
  final NavigationItem item;
  const IconNaviItemWidget(this.item, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: InkWell(
        child: item.leftBarItem,
        onTap: () {
          debugPrint('show app document');
        },
      ).padding(horizontal: 8, vertical: 2),
    );
  }
}

class NaviItemWidget extends StatelessWidget {
  final NavigationItem item;
  const NaviItemWidget(this.item, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: InkWell(
        child: item.leftBarItem,
        onTap: () {
          debugPrint('show app document');
        },
      ).padding(horizontal: 8, vertical: 2),
    );
  }
}

class NaviItemDivider extends StatelessWidget {
  final Widget child;
  const NaviItemDivider({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [child, const Text('/').padding(horizontal: 2)],
    );
  }
}

class EllipsisNaviItem extends NavigationItem {
  final List<NavigationItem> items;
  EllipsisNaviItem({
    required this.items,
  });

  @override
  Widget get leftBarItem => const FlowyText.medium('...');

  @override
  NavigationCallback get action => (id) {};

  @override
  String get identifier => "Ellipsis";
}
