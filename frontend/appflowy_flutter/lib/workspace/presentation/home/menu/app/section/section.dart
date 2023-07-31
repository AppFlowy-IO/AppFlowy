import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/app/app_bloc.dart';
import 'package:appflowy/workspace/application/menu/menu_view_section_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reorderables/reorderables.dart';

import 'item.dart';

class ViewSection extends StatelessWidget {
  final ViewDataContext appViewData;
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
              getIt<TabsBloc>().add(
                TabsEvent.openPlugin(
                  plugin: state.selectedView!.plugin(listenOnViewChanged: true),
                ),
              );
            });
          }
        },
        child: BlocBuilder<ViewSectionBloc, ViewSectionState>(
          builder: (context, state) {
            return _reorderableColumn(context, state);
          },
        ),
      ),
    );
  }

  ReorderableColumn _reorderableColumn(
    BuildContext context,
    ViewSectionState state,
  ) {
    final children = state.views.map((view) {
      final isSelected = _isViewSelected(state, view.id);
      return ViewSectionItem(
        view: view,
        key: ValueKey('$view.hashCode/$isSelected'),
        isSelected: isSelected,
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
      buildDraggableFeedback: (context, constraints, child) => ConstrainedBox(
        constraints: constraints,
        child: Material(color: Colors.transparent, child: child),
      ),
      children: children,
    );
  }

  bool _isViewSelected(ViewSectionState state, String viewId) {
    return state.selectedView?.id == viewId;
  }
}
