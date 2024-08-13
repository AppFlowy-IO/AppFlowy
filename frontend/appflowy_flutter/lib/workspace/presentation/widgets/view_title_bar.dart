import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view_title/view_title_bar_bloc.dart';
import 'package:appflowy/workspace/application/view_title/view_title_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon.dart';
import 'package:appflowy/workspace/presentation/widgets/rename_view_popover.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// workspace name > ... > view_title
class ViewTitleBar extends StatelessWidget {
  const ViewTitleBar({
    super.key,
    required this.view,
  });

  final ViewPB view;

  // late Future<List<ViewPB>> ancestors;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ViewTitleBarBloc(view: view)..add(const ViewTitleBarEvent.initial()),
      child: BlocBuilder<ViewTitleBarBloc, ViewTitleBarState>(
        builder: (context, state) {
          final ancestors = state.ancestors;
          if (ancestors.isEmpty) {
            return const SizedBox.shrink();
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              height: 24,
              child: Row(
                children: _buildViewTitles(context, ancestors),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildViewTitles(BuildContext context, List<ViewPB> views) {
    // if the level is too deep, only show the last two view, the first one view and the root view
    // for example:
    // if the views are [root, view1, view2, view3, view4, view5], only show [root, view1, ..., view4, view5]
    // if the views are [root, view1, view2, view3], show [root, view1, view2, view3]
    const lowerBound = 2;
    final upperBound = views.length - 2;
    bool hasAddedEllipsis = false;
    final children = <Widget>[];

    if (views.length <= 1) {
      return [];
    }

    // ignore the workspace name, use section name instead in the future
    // skip the workspace view
    for (var i = 1; i < views.length; i++) {
      final view = views[i];

      if (i >= lowerBound && i < upperBound) {
        if (!hasAddedEllipsis) {
          hasAddedEllipsis = true;
          children.addAll([
            const FlowyText.regular(' ... '),
            const FlowySvg(FlowySvgs.title_bar_divider_s),
          ]);
        }
        continue;
      }

      final child = FlowyTooltip(
        key: ValueKey(view.id),
        message: view.name,
        child: _ViewTitle(
          view: view,
          behavior: i == views.length - 1
              ? _ViewTitleBehavior.editable // only the last one is editable
              : _ViewTitleBehavior.uneditable, // others are not editable
          onUpdated: () {
            context
                .read<ViewTitleBarBloc>()
                .add(const ViewTitleBarEvent.reload());
          },
        ),
      );

      children.add(child);

      if (i != views.length - 1) {
        // if not the last one, add a divider
        children.add(const FlowySvg(FlowySvgs.title_bar_divider_s));
      }
    }
    return children;
  }
}

enum _ViewTitleBehavior {
  editable,
  uneditable,
}

class _ViewTitle extends StatefulWidget {
  const _ViewTitle({
    required this.view,
    this.behavior = _ViewTitleBehavior.editable,
    required this.onUpdated,
  });

  final ViewPB view;
  final _ViewTitleBehavior behavior;
  final VoidCallback onUpdated;

  @override
  State<_ViewTitle> createState() => _ViewTitleState();
}

class _ViewTitleState extends State<_ViewTitle> {
  final popoverController = PopoverController();
  final textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    popoverController.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditable = widget.behavior == _ViewTitleBehavior.editable;

    return BlocProvider(
      create: (_) =>
          ViewTitleBloc(view: widget.view)..add(const ViewTitleEvent.initial()),
      child: BlocConsumer<ViewTitleBloc, ViewTitleState>(
        listenWhen: (previous, current) {
          if (previous.view == null || current.view == null) {
            return false;
          }

          return previous.view != current.view;
        },
        listener: (_, state) {
          _resetTextEditingController(state);
          widget.onUpdated();
        },
        builder: (context, state) {
          // root view
          if (widget.view.parentViewId.isEmpty) {
            return Row(
              children: [
                FlowyText.regular(state.name),
                const HSpace(4.0),
              ],
            );
          } else if (widget.view.isSpace) {
            return _buildSpaceTitle(context, state);
          } else if (isEditable) {
            return _buildEditableViewTitle(context, state);
          } else {
            return _buildUnEditableViewTitle(context, state);
          }
        },
      ),
    );
  }

  Widget _buildSpaceTitle(BuildContext context, ViewTitleState state) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      child: _buildIconAndName(context, state, false),
    );
  }

  Widget _buildUnEditableViewTitle(BuildContext context, ViewTitleState state) {
    return Listener(
      onPointerDown: (_) => context.read<TabsBloc>().openPlugin(widget.view),
      child: SizedBox(
        height: 32.0,
        child: FlowyButton(
          useIntrinsicWidth: true,
          margin: const EdgeInsets.symmetric(horizontal: 6.0),
          text: _buildIconAndName(context, state, false),
        ),
      ),
    );
  }

  Widget _buildEditableViewTitle(BuildContext context, ViewTitleState state) {
    return AppFlowyPopover(
      constraints: const BoxConstraints(
        maxWidth: 300,
        maxHeight: 44,
      ),
      controller: popoverController,
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: const Offset(0, 6),
      popupBuilder: (context) {
        // icon + textfield
        _resetTextEditingController(state);
        return RenameViewPopover(
          viewId: widget.view.id,
          name: widget.view.name,
          popoverController: popoverController,
          icon: widget.view.defaultIcon(),
          emoji: state.icon,
        );
      },
      child: SizedBox(
        height: 32.0,
        child: FlowyButton(
          useIntrinsicWidth: true,
          margin: const EdgeInsets.symmetric(horizontal: 6.0),
          text: _buildIconAndName(context, state, true),
        ),
      ),
    );
  }

  Widget _buildIconAndName(
    BuildContext context,
    ViewTitleState state,
    bool isEditable,
  ) {
    final spaceIcon = state.view?.buildSpaceIconSvg(context);
    return SingleChildScrollView(
      child: Row(
        children: [
          if (state.icon.isNotEmpty) ...[
            FlowyText.emoji(
              state.icon,
              fontSize: 14.0,
              figmaLineHeight: 18.0,
            ),
            const HSpace(4.0),
          ],
          if (state.view?.isSpace == true && spaceIcon != null) ...[
            SpaceIcon(
              dimension: 14,
              svgSize: 8.5,
              space: state.view!,
              cornerRadius: 4,
            ),
            const HSpace(6.0),
          ],
          Opacity(
            opacity: isEditable ? 1.0 : 0.5,
            child: FlowyText.regular(
              state.name,
              fontSize: 14.0,
              overflow: TextOverflow.ellipsis,
              figmaLineHeight: 18.0,
            ),
          ),
        ],
      ),
    );
  }

  void _resetTextEditingController(ViewTitleState state) {
    textEditingController
      ..text = state.name
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: state.name.length,
      );
  }
}
