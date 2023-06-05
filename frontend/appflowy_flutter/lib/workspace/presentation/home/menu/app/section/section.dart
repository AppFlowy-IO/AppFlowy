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
  const ViewSection({final Key? key, required this.appViewData}) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return BlocProvider(
      create: (final context) {
        final bloc = ViewSectionBloc(appViewData: appViewData);
        bloc.add(const ViewSectionEvent.initial());
        return bloc;
      },
      child: BlocListener<ViewSectionBloc, ViewSectionState>(
        listenWhen: (final p, final c) => p.selectedView != c.selectedView,
        listener: (final context, final state) {
          if (state.selectedView != null) {
            WidgetsBinding.instance.addPostFrameCallback((final _) {
              getIt<HomeStackManager>().setPlugin(state.selectedView!.plugin());
            });
          }
        },
        child: BlocBuilder<ViewSectionBloc, ViewSectionState>(
          builder: (final context, final state) {
            return _reorderableColumn(context, state);
          },
        ),
      ),
    );
  }

  ReorderableColumn _reorderableColumn(
    final BuildContext context,
    final ViewSectionState state,
  ) {
    final children = state.views.map((final view) {
      return ViewSectionItem(
        key: ValueKey(view.id),
        view: view,
        isSelected: _isViewSelected(state, view.id),
        onSelected: (final view) => getIt<MenuSharedState>().latestOpenView = view,
      );
    }).toList();

    return ReorderableColumn(
      needsLongPressDraggable: false,
      onReorder: (final oldIndex, final index) {
        context
            .read<ViewSectionBloc>()
            .add(ViewSectionEvent.moveView(oldIndex, index));
      },
      ignorePrimaryScrollController: true,
      buildDraggableFeedback: (final context, final constraints, final child) => ConstrainedBox(
        constraints: constraints,
        child: Material(color: Colors.transparent, child: child),
      ),
      children: children,
    );
  }

  bool _isViewSelected(final ViewSectionState state, final String viewId) {
    final view = state.selectedView;
    if (view == null) {
      return false;
    }
    return view.id == viewId;
  }
}
