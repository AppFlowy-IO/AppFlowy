import 'package:app_flowy/home/domain/page_stack/page_stack_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/home/presentation/widgets/blank_page.dart';
import 'package:app_flowy/home/presentation/widgets/fading_index_stack.dart';
import 'package:app_flowy/home/presentation/widgets/prelude.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

List<PageType> pages = PageType.values.toList();
enum PageType {
  blank,
}

abstract class PageContext extends Equatable {
  final PageType pageType;
  final String pageTitle;
  const PageContext(this.pageType, {required this.pageTitle});
}

class HomePageStack {
  final PageStackBloc _bloc = PageStackBloc();
  HomePageStack();

  String title() {
    return _bloc.state.pageContext.pageTitle;
  }

  void setPageContext(PageContext? newContext) {
    _bloc
        .add(PageStackEvent.setContext(newContext ?? const BlankPageContext()));
  }

  Widget stackTopBar() {
    return BlocProvider<PageStackBloc>(
      create: (context) => _bloc,
      child: BlocBuilder<PageStackBloc, PageStackState>(
        builder: (context, state) {
          return HomeTopBar(
            title: state.pageContext.pageTitle,
          );
        },
      ),
    );
  }

  Widget stackWidget() {
    return BlocProvider<PageStackBloc>(
      create: (context) => _bloc,
      child: BlocBuilder<PageStackBloc, PageStackState>(
        builder: (context, state) {
          final pageContext = state.pageContext;
          return FadingIndexedStack(
            index: pages.indexOf(pageContext.pageType),
            children: buildPagesWidget(pageContext),
          );
        },
      ),
    );
  }
}

List<Widget> buildPagesWidget(PageContext pageContext) {
  return PageType.values.map((pageType) {
    if (pageType == pageContext.pageType) {
      return pageType.builder(pageContext);
    } else {
      return const BlankPage(context: BlankPageContext());
    }
  }).toList();
}

extension PageTypeExtension on PageType {
  HomeStackPage builder(PageContext context) {
    switch (this) {
      case PageType.blank:
        return BlankPage(context: context);
    }
  }
}

abstract class HomeStackPage extends StatefulWidget {
  final PageContext pageContext;
  const HomeStackPage({Key? key, required this.pageContext}) : super(key: key);
}
