import 'package:app_flowy/workspace/domain/page_stack/page_stack_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/workspace/presentation/widgets/blank_page.dart';
import 'package:app_flowy/workspace/presentation/widgets/fading_index_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/prelude.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

List<ViewType> pages = ViewType.values.toList();

abstract class HomeStackContext extends Equatable {
  final ViewType type;
  final String title;
  const HomeStackContext({required this.type, required this.title});
}

class HomePageStack {
  final PageStackBloc _bloc = PageStackBloc();
  HomePageStack();

  String title() {
    return _bloc.state.pageContext.title;
  }

  void setPageContext(HomeStackContext? newContext) {
    _bloc.add(PageStackEvent.setContext(newContext ?? BlankPageContext()));
  }

  Widget stackTopBar() {
    return BlocProvider<PageStackBloc>(
      create: (context) => _bloc,
      child: BlocBuilder<PageStackBloc, PageStackState>(
        builder: (context, state) {
          return HomeTopBar(
            title: state.pageContext.title,
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
            index: pages.indexOf(pageContext.type),
            children: buildPagesWidget(pageContext),
          );
        },
      ),
    );
  }
}

List<Widget> buildPagesWidget(HomeStackContext pageContext) {
  return ViewType.values.map((viewType) {
    if (viewType == pageContext.type) {
      return viewType.builderDisplayWidget(pageContext);
    } else {
      return const BlankPage(context: BlankPageContext());
    }
  }).toList();
}

extension PageTypeExtension on ViewType {
  HomeStackWidget builderDisplayWidget(HomeStackContext context) {
    switch (this) {
      case ViewType.Blank:
        return BlankPage(context: context as BlankPageContext);
      case ViewType.Doc:
        return BlankPage(context: context as BlankPageContext);
      default:
        return BlankPage(context: context as BlankPageContext);
    }
  }
}

abstract class HomeStackWidget extends StatefulWidget {
  final HomeStackContext pageContext;
  const HomeStackWidget({Key? key, required this.pageContext})
      : super(key: key);
}
