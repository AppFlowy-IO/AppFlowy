import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/document.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/import/import_panel.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class ViewAddButton extends StatelessWidget {
  const ViewAddButton({
    super.key,
    required this.parentViewId,
    required this.onEditing,
    required this.onSelected,
  });

  final String parentViewId;
  final void Function(bool value) onEditing;
  final Function(
    PluginBuilder,
    String? name,
    List<int>? initialDataBytes,
    bool openAfterCreated,
    bool createNewView,
  ) onSelected;

  List<PopoverAction> get _actions {
    return [
      // document, grid, kanban, calendar
      ...pluginBuilders().map(
        (pluginBuilder) => ViewAddButtonActionWrapper(
          pluginBuilder: pluginBuilder,
        ),
      ),
      // import from ...
      ...getIt<PluginSandbox>().builders.whereType<DocumentPluginBuilder>().map(
            (pluginBuilder) => ViewImportActionWrapper(
              pluginBuilder: pluginBuilder,
            ),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<PopoverAction>(
      direction: PopoverDirection.bottomWithLeftAligned,
      actions: _actions,
      offset: const Offset(0, 8),
      constraints: const BoxConstraints(
        minWidth: 200,
      ),
      buildChild: (popover) {
        return FlowyIconButton(
          width: 24,
          icon: const FlowySvg(FlowySvgs.view_item_add_s),
          onPressed: () {
            onEditing(true);
            popover.show();
          },
        );
      },
      onSelected: (action, popover) {
        onEditing(false);
        if (action is ViewAddButtonActionWrapper) {
          _showViewAddButtonActions(context, action);
        } else if (action is ViewImportActionWrapper) {
          _showViewImportAction(context, action);
        }
        popover.close();
      },
      onClosed: () {
        onEditing(false);
      },
    );
  }

  void _showViewAddButtonActions(
    BuildContext context,
    ViewAddButtonActionWrapper action,
  ) {
    onSelected(action.pluginBuilder, null, null, true, true);
  }

  void _showViewImportAction(
    BuildContext context,
    ViewImportActionWrapper action,
  ) {
    showImportPanel(
      parentViewId,
      context,
      (type, name, initialDataBytes) {
        onSelected(action.pluginBuilder, null, null, true, false);
      },
    );
  }
}

class ViewAddButtonActionWrapper extends ActionCell {
  ViewAddButtonActionWrapper({
    required this.pluginBuilder,
  });

  final PluginBuilder pluginBuilder;

  @override
  Widget? leftIcon(Color iconColor) => FlowySvg(
        pluginBuilder.icon,
        size: const Size.square(16),
      );

  @override
  String get name => pluginBuilder.menuName;

  PluginType get pluginType => pluginBuilder.pluginType;
}

class ViewImportActionWrapper extends ActionCell {
  ViewImportActionWrapper({
    required this.pluginBuilder,
  });

  final DocumentPluginBuilder pluginBuilder;

  @override
  Widget? leftIcon(Color iconColor) => const FlowySvg(FlowySvgs.icon_import_s);

  @override
  String get name => LocaleKeys.moreAction_import.tr();
}
