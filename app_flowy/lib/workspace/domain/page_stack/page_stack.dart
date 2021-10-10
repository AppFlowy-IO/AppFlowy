import 'package:app_flowy/workspace/presentation/stack_page/doc/doc_stack_page.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flowy/workspace/presentation/stack_page/blank/blank_page.dart';
import 'package:app_flowy/workspace/presentation/stack_page/fading_index_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/prelude.dart';

abstract class HomeStackContext extends Equatable {
  String get title;
  String get identifier;
  ViewType get type;
  Widget render();
}

HomeStackContext stackCtxFromView(View view) {
  switch (view.viewType) {
    case ViewType.Blank:
      return DefaultHomeStackContext();
    case ViewType.Doc:
      return DocStackContext(view: view);
    default:
      return DefaultHomeStackContext();
  }
}

class HomeStackNotifier extends ChangeNotifier {
  HomeStackContext inner;

  HomeStackNotifier({
    HomeStackContext? context,
  }) : inner = context ?? DefaultHomeStackContext();

  set context(HomeStackContext context) {
    inner = context;
    notifyListeners();
  }

  HomeStackContext get context => inner;
}

// HomePageStack is initialized as singleton to controll the page stack.
class HomeStack {
  final HomeStackNotifier _notifier = HomeStackNotifier();
  HomeStack();

  String title() {
    return _notifier.context.title;
  }

  void setStack(HomeStackContext context) {
    _notifier.context = context;
  }

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
              return const AnnouncementStackPage();
            }
          }).toList(),
        );
      }),
    );
  }
}

List<ViewType> pages = ViewType.values.toList();
