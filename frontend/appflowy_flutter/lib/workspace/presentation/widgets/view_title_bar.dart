import 'dart:math';

import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/startup/tasks/app_window_size_manager.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/widgets/rename_view_popover.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// workspace name / ... / view_title
class ViewTitleBar extends StatefulWidget {
  const ViewTitleBar({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  State<ViewTitleBar> createState() => _ViewTitleBarState();
}

class _ViewTitleBarState extends State<ViewTitleBar> {
  late Future<List<ViewPB>> ancestors;
  late String viewId;

  @override
  void initState() {
    super.initState();

    viewId = widget.view.id;
    _reloadAncestors(viewId);
  }

  @override
  void didUpdateWidget(covariant ViewTitleBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.view.id != widget.view.id) {
      viewId = widget.view.id;
      _reloadAncestors(viewId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ViewPB>>(
      future: ancestors,
      builder: (context, snapshot) {
        final ancestors = snapshot.data;
        if (ancestors == null ||
            snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        const maxWidth = WindowSizeManager.minWindowWidth / 2.0;
        final replacement = Row(
          // refresh the view title bar when the ancestors changed
          key: ValueKey(ancestors.hashCode),
          children: _buildViewTitles(context, ancestors),
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            return Visibility(
              visible: constraints.maxWidth < maxWidth,
              replacement: replacement,
              // if the width is too small, only show one view title bar without the ancestors
              child: _ViewTitle(
                key: ValueKey(ancestors.last),
                view: ancestors.last,
                maxTitleWidth: constraints.maxWidth,
                onUpdated: () => setState(() => _reloadAncestors(viewId)),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildViewTitles(BuildContext context, List<ViewPB> views) {
    // if the level is too deep, only show the last two view, the first one view and the root view
    bool hasAddedEllipsis = false;
    final children = <Widget>[];

    for (var i = 0; i < views.length; i++) {
      final view = views[i];

      if (i >= 1 && i < views.length - 2) {
        if (!hasAddedEllipsis) {
          hasAddedEllipsis = true;
          children.add(
            const FlowyText.regular(' ... /'),
          );
        }
        continue;
      }

      Widget child;
      if (i == 0) {
        final currentWorkspace =
            context.read<UserWorkspaceBloc>().state.currentWorkspace;
        final icon = currentWorkspace?.icon ?? '';
        final name = currentWorkspace?.name ?? view.name;
        // the first one is the workspace name
        child = FlowyTooltip(
          message: name,
          child: Row(
            children: [
              EmojiText(
                emoji: icon,
                fontSize: 18.0,
              ),
              const HSpace(2.0),
              FlowyText.regular(name),
              const HSpace(4.0),
            ],
          ),
        );
      } else {
        child = FlowyTooltip(
          message: view.name,
          child: _ViewTitle(
            view: view,
            behavior: i == views.length - 1
                ? _ViewTitleBehavior.editable // only the last one is editable
                : _ViewTitleBehavior.uneditable, // others are not editable
            onUpdated: () => setState(() => _reloadAncestors(viewId)),
          ),
        );
      }

      children.add(child);

      if (i != views.length - 1) {
        // if not the last one, add a divider
        children.add(const FlowyText.regular('/'));
      }
    }
    return children;
  }

  void _reloadAncestors(String viewId) {
    ancestors = ViewBackendService.getViewAncestors(viewId)
        .fold((s) => s.items, (f) => []);
  }
}

enum _ViewTitleBehavior {
  editable,
  uneditable,
}

class _ViewTitle extends StatefulWidget {
  const _ViewTitle({
    super.key,
    required this.view,
    this.behavior = _ViewTitleBehavior.editable,
    this.maxTitleWidth = 180,
    required this.onUpdated,
  });

  final ViewPB view;
  final _ViewTitleBehavior behavior;
  final double maxTitleWidth;
  final VoidCallback onUpdated;

  @override
  State<_ViewTitle> createState() => _ViewTitleState();
}

class _ViewTitleState extends State<_ViewTitle> {
  final popoverController = PopoverController();
  final textEditingController = TextEditingController();
  late final viewListener = ViewListener(viewId: widget.view.id);

  String name = '';
  String icon = '';
  String inputtingName = '';

  @override
  void initState() {
    super.initState();

    name = widget.view.name;
    icon = widget.view.icon.value;

    _resetTextEditingController();
    viewListener.start(
      onViewUpdated: (view) {
        if (name != view.name || icon != view.icon.value) {
          widget.onUpdated();
        }
        setState(() {
          name = view.name;
          icon = view.icon.value;
          _resetTextEditingController();
        });
      },
    );
  }

  @override
  void dispose() {
    textEditingController.dispose();
    popoverController.close();
    viewListener.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // root view
    if (widget.view.parentViewId.isEmpty) {
      return Row(
        children: [
          FlowyText.regular(name),
          const HSpace(4.0),
        ],
      );
    }

    final child = SingleChildScrollView(
      child: Row(
        children: [
          EmojiText(
            emoji: icon,
            fontSize: 18.0,
          ),
          const HSpace(2.0),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: max(0, widget.maxTitleWidth),
            ),
            child: FlowyText.regular(
              name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (widget.behavior == _ViewTitleBehavior.uneditable) {
      return Listener(
        onPointerDown: (_) => context.read<TabsBloc>().openPlugin(widget.view),
        child: FlowyButton(
          useIntrinsicWidth: true,
          onTap: () {},
          text: child,
        ),
      );
    }

    return AppFlowyPopover(
      constraints: const BoxConstraints(
        maxWidth: 300,
        maxHeight: 44,
      ),
      controller: popoverController,
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: const Offset(0, 18),
      popupBuilder: (context) {
        // icon + textfield
        _resetTextEditingController();
        return RenameViewPopover(
          viewId: widget.view.id,
          name: widget.view.name,
          popoverController: popoverController,
          icon: widget.view.defaultIcon(),
          emoji: icon,
        );
      },
      child: FlowyButton(
        useIntrinsicWidth: true,
        text: child,
      ),
    );
  }

  void _resetTextEditingController() {
    inputtingName = name;
    textEditingController
      ..text = name
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: name.length,
      );
  }
}
