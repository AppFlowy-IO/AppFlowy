import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flowy/workspace/presentation/doc/doc_page.dart';
import 'package:app_flowy/workspace/presentation/widgets/blank_page.dart';
import 'package:app_flowy/workspace/presentation/widgets/fading_index_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/prelude.dart';

abstract class HomeStackView extends Equatable {
  final ViewType type;
  final String title;
  final String identifier;
  const HomeStackView(
      {required this.type, required this.title, required this.identifier});
}

class PageStackNotifier extends ChangeNotifier {
  HomeStackView? innerView;

  PageStackNotifier({
    this.innerView,
  });

  set view(HomeStackView view) {
    innerView = view;
    notifyListeners();
  }

  HomeStackView get view {
    return innerView ?? const AnnouncementStackView();
  }
}

// HomePageStack is initialized as singleton to controll the page stack.
class HomePageStack {
  final PageStackNotifier _notifier = PageStackNotifier();
  HomePageStack();

  String title() {
    return _notifier.view.title;
  }

  void setStackView(HomeStackView? stackView) {
    _notifier.view = stackView ?? const AnnouncementStackView();
  }

  Widget stackTopBar() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _notifier),
      ],
      child: Consumer(builder: (ctx, PageStackNotifier notifier, child) {
        return HomeTopBar(view: notifier.view);
      }),
    );
  }

  Widget stackWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _notifier),
      ],
      child: Consumer(builder: (ctx, PageStackNotifier notifier, child) {
        return FadingIndexedStack(
          index: pages.indexOf(notifier.view.type),
          children: _buildStackWidget(notifier.view),
        );
      }),
    );
  }
}

List<ViewType> pages = ViewType.values.toList();

List<Widget> _buildStackWidget(HomeStackView stackView) {
  return ViewType.values.map((viewType) {
    if (viewType == stackView.type) {
      switch (stackView.type) {
        case ViewType.Blank:
          return AnnouncementPage(
              stackView: stackView as AnnouncementStackView);
        case ViewType.Doc:
          final docView = stackView as DocPageStackView;
          return DocPage(key: ValueKey(docView.view.id), stackView: docView);
        default:
          return AnnouncementPage(
              stackView: stackView as AnnouncementStackView);
      }
    } else {
      return const AnnouncementPage(stackView: AnnouncementStackView());
    }
  }).toList();
}

HomeStackView stackViewFromView(View view) {
  switch (view.viewType) {
    case ViewType.Blank:
      return const AnnouncementStackView();
    case ViewType.Doc:
      return DocPageStackView(view);
    default:
      return const AnnouncementStackView();
  }
}

abstract class HomeStackWidget extends StatefulWidget {
  final HomeStackView stackView;
  const HomeStackWidget({Key? key, required this.stackView}) : super(key: key);
}
