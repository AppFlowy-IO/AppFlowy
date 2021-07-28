import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/home_top_bar.dart';
import 'package:flowy_infra_ui/style_widget/text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

typedef NaviAction = void Function();

abstract class NaviItem {
  String get identifier;
  String get title;
  NaviAction get action;
}

class NavigationNotifier with ChangeNotifier {
  PageStackNotifier pageStackNotifier;
  NavigationNotifier(this.pageStackNotifier);

  void update(PageStackNotifier notifier) {
    pageStackNotifier = notifier;
    notifyListeners();
  }

  List<NaviItem> get naviItems {
    List<NaviItem> items = [
      ViewNaviItemImpl(pageStackNotifier.view),
      // ViewNaviItemImpl(pageStackNotifier.view),
      // ViewNaviItemImpl(pageStackNotifier.view),
      // ViewNaviItemImpl(pageStackNotifier.view),
      // ViewNaviItemImpl(pageStackNotifier.view),
      // ViewNaviItemImpl(pageStackNotifier.view)
    ];
    return items;
  }
}

class StyledNavigationList extends StatelessWidget {
  const StyledNavigationList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProxyProvider<PageStackNotifier, NavigationNotifier>(
      create: (_) => NavigationNotifier(
        Provider.of<PageStackNotifier>(
          context,
          listen: false,
        ),
      ),
      update: (_, notifier, controller) => controller!..update(notifier),
      child: Consumer(builder: (ctx, NavigationNotifier notifier, child) {
        return Row(children: _renderChildren(notifier.naviItems));
      }),
    );
  }

  List<Widget> _renderChildren(List<NaviItem> items) {
    if (items.isEmpty) {
      return [];
    }

    List<NaviItem> newItems = _filter(items);
    Widget last = NaviItemWidget(newItems.removeLast());

    List<Widget> widgets = List.empty(growable: true);
    widgets.addAll(newItems
        .map((item) => NaviItemDivider(child: NaviItemWidget(item)))
        .toList());
    widgets.add(last);

    return widgets;
  }

  List<NaviItem> _filter(List<NaviItem> items) {
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
  final NaviItem item;
  const NaviItemWidget(this.item, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: FlowyTextButton(
        item.title,
        fontSize: 14,
        onPressed: () {
          debugPrint('show app document');
        },
      ),
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

class EllipsisNaviItem extends NaviItem {
  final List<NaviItem> items;
  EllipsisNaviItem({
    required this.items,
  });

  @override
  NaviAction get action => throw UnimplementedError();

  @override
  String get identifier => "Ellipsis";

  @override
  String get title => "...";
}
