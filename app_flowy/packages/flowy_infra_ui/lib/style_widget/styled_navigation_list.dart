import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef NaviAction = void Function(String);

abstract class NaviItem {
  String get identifier;
  NaviAction get action;
}

class StyledNavigationController extends ChangeNotifier {
  List<NaviItem> naviItems;
  StyledNavigationController({this.naviItems = const []});
}

class StyledNavigationList extends StatelessWidget {
  const StyledNavigationList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StyledNavigationController()),
      ],
      child: Consumer(builder: (ctx, StyledNavigationController ctrl, child) {
        return Row(
          children: _buildNaviItemWidget(ctrl.naviItems),
        );
      }),
    );
  }

  List<Widget> _buildNaviItemWidget(List<NaviItem> items) {
    if (items.isEmpty) {
      return [];
    }

    List<NaviItem> newItems = _filter(items);
    Widget last = NaviItemWidget(newItems.removeLast());

    List<Widget> widgets = newItems
        .map((item) => NaviItemDivider(child: NaviItemWidget(item)))
        .toList();

    widgets.add(last);

    return widgets;
  }

  List<NaviItem> _filter(List<NaviItem> items) {
    final length = items.length;
    if (length > 4) {
      final ellipsisItems = items.getRange(1, length - 2).toList();
      return [
        items[0],
        EllipsisNaviItem(items: ellipsisItems),
        items[length - 2],
        items[length - 1]
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
    return Container(
      child: null,
    );
  }
}

class NaviItemDivider extends StatelessWidget {
  final Widget child;
  const NaviItemDivider({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [child, const Text('/')],
    );
  }
}

class EllipsisNaviItem extends NaviItem {
  final List<NaviItem> items;
  EllipsisNaviItem({
    required this.items,
  });

  @override
  // TODO: implement action
  NaviAction get action => throw UnimplementedError();

  @override
  // TODO: implement identifier
  String get identifier => throw UnimplementedError();
}
