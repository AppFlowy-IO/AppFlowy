import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/presentation/stack_page/blank/blank_page.dart';
import 'package:app_flowy/workspace/presentation/stack_page/doc/doc_stack_page.dart';
import 'package:app_flowy/workspace/presentation/stack_page/home_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/prelude.dart';

typedef NavigationCallback = void Function(String id);

abstract class NavigationItem {
  String get title;
  String get identifier;

  NavigationCallback get action => (id) {
        getIt<HomeStackManager>().setStackWithId(id);
      };
}

abstract class HomeStackContext extends Equatable with NavigationItem {
  List<NavigationItem> get navigationItems;

  @override
  String get title;

  @override
  String get identifier;

  ViewType get type;

  Widget render();
}

HomeStackContext stackCtxFromView(View view) {
  switch (view.viewType) {
    case ViewType.Blank:
      return BlankStackContext();
    case ViewType.Doc:
      return DocStackContext(view: view);
    default:
      return BlankStackContext();
  }
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

  String title() {
    return _notifier.context.title;
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
          children: ViewType.values.map((viewType) {
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

List<ViewType> pages = ViewType.values.toList();
