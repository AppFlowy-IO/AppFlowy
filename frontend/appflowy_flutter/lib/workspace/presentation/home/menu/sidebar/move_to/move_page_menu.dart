import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_search_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MovePageMenu extends StatefulWidget {
  const MovePageMenu({
    super.key,
    required this.sourceView,
    required this.userProfile,
    required this.workspaceId,
    required this.onSelected,
  });

  final ViewPB sourceView;
  final UserProfilePB userProfile;
  final String workspaceId;
  final void Function(ViewPB view) onSelected;

  @override
  State<MovePageMenu> createState() => _MovePageMenuState();
}

class _MovePageMenuState extends State<MovePageMenu> {
  final isExpandedNotifier = PropertyValueNotifier(true);
  final isHoveredNotifier = ValueNotifier(true);

  @override
  void dispose() {
    isExpandedNotifier.dispose();
    isHoveredNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SpaceBloc()
            ..add(
              SpaceEvent.initial(
                widget.userProfile,
                widget.workspaceId,
                openFirstPage: false,
              ),
            ),
        ),
        BlocProvider(
          create: (context) => SpaceSearchBloc()
            ..add(
              const SpaceSearchEvent.initial(),
            ),
        ),
      ],
      child: BlocBuilder<SpaceBloc, SpaceState>(
        builder: (context, state) {
          final space = state.currentSpace;
          if (space == null) {
            return const SizedBox.shrink();
          }
          return Column(
            children: [
              SpaceSearchField(
                width: 240,
                onSearch: (context, value) {
                  context.read<SpaceSearchBloc>().add(
                        SpaceSearchEvent.search(
                          value,
                        ),
                      );
                },
              ),
              const VSpace(10),
              BlocBuilder<SpaceSearchBloc, SpaceSearchState>(
                builder: (context, state) {
                  if (state.queryResults == null) {
                    return Expanded(
                      child: _buildSpace(space),
                    );
                  }
                  return Expanded(
                    child: _buildGroupedViews(state.queryResults!),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupedViews(List<ViewPB> views) {
    final groupedViews = views
        .where(
          (view) =>
              !_shouldIgnoreView(view, widget.sourceView) && !view.isSpace,
        )
        .toList();
    return _MovePageGroupedViews(
      views: groupedViews,
      onSelected: widget.onSelected,
    );
  }

  Column _buildSpace(ViewPB space) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpacePopup(
          useIntrinsicWidth: false,
          expand: true,
          height: 30,
          child: CurrentSpace(
            onTapBlankArea: () {
              // move the page to current space
              widget.onSelected(space);
            },
            space: space,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: SpacePages(
              key: ValueKey(space.id),
              space: space,
              isHovered: isHoveredNotifier,
              isExpandedNotifier: isExpandedNotifier,
              shouldIgnoreView: (view) => _shouldIgnoreView(
                view,
                widget.sourceView,
              ),
              // hide the hover status and disable the editing actions
              disableSelectedStatus: true,
              // hide the ... and + buttons
              rightIconsBuilder: (context, view) => [],
              onSelected: (_, view) => widget.onSelected(view),
            ),
          ),
        ),
      ],
    );
  }
}

class _MovePageGroupedViews extends StatelessWidget {
  const _MovePageGroupedViews({
    required this.views,
    required this.onSelected,
  });

  final List<ViewPB> views;
  final void Function(ViewPB view) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: views
            .map(
              (e) => ViewItem(
                key: ValueKey(e.id),
                view: e,
                spaceType: FolderSpaceType.unknown,
                level: 0,
                onSelected: (_, view) => onSelected(view),
                isFeedback: false,
                isDraggable: false,
                shouldRenderChildren: false,
                leftIconBuilder: (_, __) => const HSpace(0.0),
                rightIconsBuilder: (_, view) => [],
              ),
            )
            .toList(),
      ),
    );
  }
}

bool _shouldIgnoreView(ViewPB view, ViewPB sourceView) {
  // ignore the source view and database view, don't render it in the list.
  if (view.layout != ViewLayoutPB.Document) {
    return true;
  }
  return view.id == sourceView.id;
}
