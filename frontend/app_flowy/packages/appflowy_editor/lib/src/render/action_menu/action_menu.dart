import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/render/action_menu/action_menu_item.dart';
import 'package:appflowy_editor/src/service/render_plugin_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

mixin ActionProvider<T extends Node> on NodeWidgetBuilder<T> {
  List<ActionMenuItem> actions(NodeWidgetContext<T> context);
}

class ActionMenuArenaMember {
  final ActionMenuState state;
  final VoidCallback listener;

  const ActionMenuArenaMember(this.state, this.listener);
}

class ActionMenuArena {
  Map<Path, ActionMenuArenaMember> _members = {};
  Set<Path> _visible = {};

  ActionMenuArena._singleton();
  static final instance = ActionMenuArena._singleton();

  void add(ActionMenuState menuState) {
    final member = ActionMenuArenaMember(menuState, () {
      if (menuState.isHover || menuState.isPinned) {
        _visible.add(menuState.path);
      } else {
        _visible.remove(menuState.path);
      }
    });
    menuState.addListener(member.listener);
    _members[menuState.path] = member;
  }

  void remove(ActionMenuState menuState) {
    final member = _members.remove(menuState.path);
    if (member != null) {
      menuState.removeListener(member.listener);
      _visible.remove(menuState.path);
    }
  }

  bool isVisible(Path path) {
    var sorted = _visible.toList()
      ..sort(
        (a, b) => a <= b ? 1 : -1,
      );
    return sorted.isNotEmpty && path == sorted.first;
  }
}

class ActionMenuState extends ChangeNotifier {
  final Path path;

  ActionMenuState(this.path) {
    ActionMenuArena.instance.add(this);
  }

  @override
  void dispose() {
    ActionMenuArena.instance.remove(this);
    super.dispose();
  }

  bool _isHover = false;
  bool _isPinned = false;

  bool get isPinned => _isPinned;
  bool get isHover => _isHover;
  bool get isVisible => ActionMenuArena.instance.isVisible(path);

  set isPinned(bool value) {
    _isPinned = value;
    notifyListeners();
  }

  set isHover(bool value) {
    _isHover = value;
    notifyListeners();
  }
}

class ActionMenuWidget extends StatelessWidget {
  final List<ActionMenuItem> items;

  const ActionMenuWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surface,
      elevation: 3.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          items.length,
          (index) {
            return ActionMenuItemWidget(
              item: items[index],
            );
          },
        ),
      ),
    );
  }
}

class ActionMenuOverlay extends StatelessWidget {
  final Widget child;
  final List<ActionMenuItem> items;
  final Positioned Function(BuildContext context, List<ActionMenuItem> items)?
      customActionMenuBuilder;

  const ActionMenuOverlay({
    super.key,
    required this.items,
    required this.child,
    this.customActionMenuBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final menuState = Provider.of<ActionMenuState>(context);

    return MouseRegion(
      onEnter: (_) {
        menuState.isHover = true;
      },
      onExit: (_) {
        menuState.isHover = false;
      },
      onHover: (_) {
        menuState.isHover = true;
      },
      child: Stack(
        children: [
          child,
          if (menuState.isVisible) _buildMenu(context),
        ],
      ),
    );
  }

  Positioned _buildMenu(BuildContext context) {
    return customActionMenuBuilder != null
        ? customActionMenuBuilder!(context, items)
        : Positioned(top: 5, right: 5, child: ActionMenuWidget(items: items));
  }
}
