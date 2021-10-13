import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

typedef NaviAction = void Function();

class NavigationNotifier with ChangeNotifier {
  HomeStackNotifier homeStackNotifier;
  NavigationNotifier(this.homeStackNotifier);

  void update(HomeStackNotifier notifier) {
    homeStackNotifier = notifier;
    notifyListeners();
  }

  List<NavigationItem> get naviItems => homeStackNotifier.context.navigationItems;
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
      create: (_) => NavigationNotifier(
        Provider.of<HomeStackNotifier>(context, listen: false),
      ),
      update: (_, notifier, controller) => controller!..update(notifier),
      child: Consumer(builder: (ctx, NavigationNotifier notifier, child) {
        return Row(children: _renderChildren(notifier.naviItems));
      }),
    );
  }

  List<Widget> _renderChildren(List<NavigationItem> items) {
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
        child: item.titleWidget,
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
        child: item.titleWidget,
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
  Widget get titleWidget => const FlowyText.medium('...');

  @override
  NavigationCallback get action => (id) {};

  @override
  String get identifier => "Ellipsis";
}
