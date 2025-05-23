import 'package:appflowy/mobile/presentation/search/mobile_view_ancestors.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/recent/recent_views_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchRecentViewCell extends StatefulWidget {
  const SearchRecentViewCell({
    super.key,
    required this.icon,
    required this.view,
    required this.onSelected,
    required this.isNarrowWindow,
  });

  final Widget icon;
  final ViewPB view;
  final VoidCallback onSelected;
  final bool isNarrowWindow;

  @override
  State<SearchRecentViewCell> createState() => _SearchRecentViewCellState();
}

class _SearchRecentViewCellState extends State<SearchRecentViewCell> {
  final focusNode = FocusNode();

  ViewPB get view => widget.view;

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final spaceL = theme.spacing.l;
    final bloc = context.read<RecentViewsBloc>(), state = bloc.state;
    final hoveredView = state.hoveredView, hasHovered = hoveredView != null;
    final hovering = hoveredView == view;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleSelection(view.id),
      child: Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _handleSelection(view.id);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        onFocusChange: (hasFocus) {
          if (hasFocus && !hovering) {
            bloc.add(RecentViewsEvent.hoverView(view));
          }
        },
        child: FlowyHover(
          onHover: (value) {
            if (hoveredView == view) return;
            bloc.add(RecentViewsEvent.hoverView(view));
          },
          style: HoverStyle(
            borderRadius: BorderRadius.circular(8),
            hoverColor: theme.fillColorScheme.contentHover,
            foregroundColorOnHover: AFThemeExtension.of(context).textColor,
          ),
          isSelected: () => hovering,
          child: Padding(
            padding: EdgeInsets.all(spaceL),
            child: Row(
              children: [
                widget.icon,
                HSpace(8),
                Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        (!widget.isNarrowWindow && hasHovered) ? 480.0 : 680.0,
                  ),
                  child: Text(
                    view.nameOrDefault,
                    maxLines: 1,
                    style: theme.textStyle.body
                        .enhanced(color: theme.textColorScheme.primary)
                        .copyWith(height: 22 / 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(child: buildPath(theme)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPath(AppFlowyThemeData theme) {
    return BlocProvider(
      key: ValueKey(view.id),
      create: (context) => ViewAncestorBloc(view.id),
      child: BlocBuilder<ViewAncestorBloc, ViewAncestorState>(
        builder: (context, state) {
          if (state.ancestor.ancestors.isEmpty) return const SizedBox.shrink();
          return state.buildOnelinePath(context);
        },
      ),
    );
  }

  /// Helper to handle the selection action.
  void _handleSelection(String id) {
    widget.onSelected();
    getIt<ActionNavigationBloc>().add(
      ActionNavigationEvent.performAction(
        action: NavigationAction(objectId: id),
      ),
    );
  }
}
