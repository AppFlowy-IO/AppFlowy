import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/app/app_bloc.dart';
import 'package:appflowy/workspace/application/menu/menu_view_section_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reorderables/reorderables.dart';

import 'item.dart';

class ViewSection extends StatelessWidget {
  final AppViewDataContext appViewData;
  const ViewSection({Key? key, required this.appViewData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = ViewSectionBloc(appViewData: appViewData);
        bloc.add(const ViewSectionEvent.initial());
        return bloc;
      },
      child: BlocListener<ViewSectionBloc, ViewSectionState>(
        listenWhen: (p, c) => p.selectedView != c.selectedView,
        listener: (context, state) {
          if (state.selectedView != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              getIt<HomeStackManager>().setPlugin(state.selectedView!.plugin());
            });
          }
        },
        child: BlocBuilder<ViewSectionBloc, ViewSectionState>(
          builder: (context, state) {
            return _reorderableColum(context, state);
          },
        ),
      ),
    );
  }

  ReorderableColumn _reorderableColum(
      BuildContext context, ViewSectionState state) {
    final children = state.views.map((view) {
      return ViewSectionItem(
        key: ValueKey(view.id),
        view: view,
        isSelected: _isViewSelected(state, view.id),
        onSelected: (view) => getIt<MenuSharedState>().latestOpenView = view,
      );
    }).toList();

    return ReorderableColumn(
      needsLongPressDraggable: false,
      onReorder: (oldIndex, index) {
        context
            .read<ViewSectionBloc>()
            .add(ViewSectionEvent.moveView(oldIndex, index));
      },
      ignorePrimaryScrollController: true,
      children: children,
    );
  }

  bool _isViewSelected(ViewSectionState state, String viewId) {
    final view = state.selectedView;
    if (view == null) {
      return false;
    }
    return view.id == viewId;
  }
}
