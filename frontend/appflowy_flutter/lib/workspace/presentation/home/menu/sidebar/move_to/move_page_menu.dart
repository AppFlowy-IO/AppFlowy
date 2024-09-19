import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_search_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef MovePageMenuOnSelected = void Function(ViewPB space, ViewPB view);

class MovePageMenu extends StatefulWidget {
  const MovePageMenu({
    super.key,
    required this.sourceView,
    required this.onSelected,
  });

  final ViewPB sourceView;
  final MovePageMenuOnSelected onSelected;

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
    return BlocProvider(
      create: (context) => SpaceSearchBloc()
        ..add(
          const SpaceSearchEvent.initial(),
        ),
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
                    child: _buildGroupedViews(space, state.queryResults!),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupedViews(ViewPB space, List<ViewPB> views) {
    final groupedViews = views
        .where(
          (view) =>
              !_shouldIgnoreView(view, widget.sourceView) && !view.isSpace,
        )
        .toList();
    return _MovePageGroupedViews(
      views: groupedViews,
      onSelected: (view) => widget.onSelected(space, view),
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
          showCreateButton: false,
          child: FlowyTooltip(
            message: LocaleKeys.space_switchSpace.tr(),
            child: CurrentSpace(
              onTapBlankArea: () {
                // move the page to current space
                widget.onSelected(space, space);
              },
              space: space,
            ),
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
              shouldIgnoreView: (view) {
                debugPrint(
                  'view: ${view.id}, layout: ${view.layout}, sourceView: ${widget.sourceView.id}',
                );
                if (_shouldIgnoreView(view, widget.sourceView)) {
                  return IgnoreViewType.hide;
                }
                if (view.layout != ViewLayoutPB.Document) {
                  return IgnoreViewType.disable;
                }
                return IgnoreViewType.none;
              },
              // hide the hover status and disable the editing actions
              disableSelectedStatus: true,
              // hide the ... and + buttons
              rightIconsBuilder: (context, view) => [],
              onSelected: (_, view) => widget.onSelected(space, view),
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
        children: views.map(
          (e) {
            final child = ViewItem(
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
            );

            return child;
          },
        ).toList(),
      ),
    );
  }
}

bool _shouldIgnoreView(ViewPB view, ViewPB sourceView) {
  return view.id == sourceView.id;
}
