import 'package:app_flowy/workspace/domain/page_stack/page_stack_bloc.dart';
import 'package:app_flowy/workspace/presentation/doc/doc_page.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/workspace/presentation/widgets/blank_page.dart';
import 'package:app_flowy/workspace/presentation/widgets/fading_index_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/prelude.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class HomeStackView extends Equatable {
  final ViewType type;
  final String title;
  const HomeStackView({required this.type, required this.title});
}

class HomePageStack {
  final PageStackBloc _bloc = PageStackBloc();
  HomePageStack();

  String title() {
    return _bloc.state.stackView.title;
  }

  void setStackView(HomeStackView? stackView) {
    _bloc.add(PageStackEvent.setStackView(stackView ?? const BlankStackView()));
  }

  Widget stackTopBar() {
    return BlocProvider<PageStackBloc>(
      create: (context) => _bloc,
      child: BlocBuilder<PageStackBloc, PageStackState>(
        builder: (context, state) {
          return HomeTopBar(
            view: state.stackView,
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
          return FadingIndexedStack(
            index: pages.indexOf(state.stackView.type),
            children: _buildStackWidget(state.stackView),
          );
        },
      ),
    );
  }
}

List<ViewType> pages = ViewType.values.toList();

List<Widget> _buildStackWidget(HomeStackView stackView) {
  return ViewType.values.map((viewType) {
    if (viewType == stackView.type) {
      switch (stackView.type) {
        case ViewType.Blank:
          return BlankPage(stackView: stackView as BlankStackView);
        case ViewType.Doc:
          final docView = stackView as DocPageStackView;
          return DocPage(key: ValueKey(docView.view.id), stackView: docView);
        default:
          return BlankPage(stackView: stackView as BlankStackView);
      }
    } else {
      return const BlankPage(stackView: BlankStackView());
    }
  }).toList();
}

HomeStackView stackViewFromView(View view) {
  switch (view.viewType) {
    case ViewType.Blank:
      return const BlankStackView();
    case ViewType.Doc:
      return DocPageStackView(view);
    default:
      return const BlankStackView();
  }
}

abstract class HomeStackWidget extends StatefulWidget {
  final HomeStackView stackView;
  const HomeStackWidget({Key? key, required this.stackView}) : super(key: key);
}
