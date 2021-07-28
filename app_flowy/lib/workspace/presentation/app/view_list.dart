import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/view/view_list_bloc.dart';
import 'package:app_flowy/workspace/presentation/view/view_widget.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ViewList extends StatelessWidget {
  final List<View> views;
  const ViewList(this.views, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<ViewListBloc>(param1: views)..add(ViewListEvent.initial(views)),
      child: BlocBuilder<ViewListBloc, ViewListState>(
        builder: (context, state) {
          return state.views.fold(
            () => const SizedBox(),
            (views) => _renderViews(context, views),
          );
        },
      ),
    );
  }

  Widget _renderViews(BuildContext context, List<View> views) {
    var viewWidgets = views.map((view) {
      final viewCtx = ViewWidgetContext(view,
          isSelected: _isViewSelected(context, view.id));

      final viewWidget = ViewWidget(
        viewCtx: viewCtx,
        onOpen: (view) {
          context.read<ViewListBloc>().add(ViewListEvent.openView(view));
          final stackView = stackViewFromView(viewCtx.view);
          getIt<HomePageStack>().setStackView(stackView);
        },
      );

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: viewWidget,
      );
    }).toList(growable: false);

    return Column(
      children: viewWidgets,
    );
  }

  bool _isViewSelected(BuildContext context, String viewId) {
    return context
        .read<ViewListBloc>()
        .state
        .selectedView
        .fold(() => false, (selectedViewId) => viewId == selectedViewId);
  }
}
