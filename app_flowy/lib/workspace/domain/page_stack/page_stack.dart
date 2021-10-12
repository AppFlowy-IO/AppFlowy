import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/presentation/stack_page/blank/blank_page.dart';
import 'package:app_flowy/workspace/presentation/stack_page/home_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/prelude.dart';

typedef NavigationCallback = void Function(String id);

abstract class NavigationItem {
  Widget get titleWidget;
  String get identifier;

  NavigationCallback get action => (id) {
        getIt<HomeStackManager>().setStackWithId(id);
      };
}

enum HomeStackType {
  blank,
  doc,
  trash,
}

List<HomeStackType> pages = HomeStackType.values.toList();

abstract class HomeStackContext extends Equatable with NavigationItem {
  List<NavigationItem> get navigationItems;

  @override
  Widget get titleWidget;

  @override
  String get identifier;

  HomeStackType get type;

  Widget render();
}

class HomeStackNotifier extends ChangeNotifier {
  HomeStackContext inner;
  HomeStackNotifier({HomeStackContext? context}) : inner = context ?? BlankStackContext();

  set context(HomeStackContext context) {
    inner = context;
    notifyListeners();
  }

  HomeStackContext get context => inner;
}

// HomeStack is initialized as singleton to controll the page stack.
class HomeStackManager {
  final HomeStackNotifier _notifier = HomeStackNotifier();
  HomeStackManager();

  Widget title() {
    return _notifier.context.titleWidget;
  }

  void setStack(HomeStackContext context) {
    _notifier.context = context;
  }

  void setStackWithId(String id) {}

  Widget stackTopBar() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _notifier),
      ],
      child: Consumer(builder: (ctx, HomeStackNotifier notifier, child) {
        return HomeTopBar(view: notifier.context);
      }),
    );
  }

  Widget stackWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _notifier),
      ],
      child: Consumer(builder: (ctx, HomeStackNotifier notifier, child) {
        return FadingIndexedStack(
          index: pages.indexOf(notifier.context.type),
          children: HomeStackType.values.map((viewType) {
            if (viewType == notifier.context.type) {
              return notifier.context.render();
            } else {
              return const BlankStackPage();
            }
          }).toList(),
        );
      }),
    );
  }
}
