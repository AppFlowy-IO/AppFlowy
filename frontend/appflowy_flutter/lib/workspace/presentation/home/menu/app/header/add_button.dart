import 'package:appflowy/plugins/document/document.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/header/import/import_panel.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart' show Document;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

class AddButton extends StatelessWidget {
  final Function(
    PluginBuilder,
    Document? document,
  ) onSelected;

  const AddButton({
    Key? key,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<PopoverAction> actions = [];

    // Plugins
    actions.addAll(
      pluginBuilders()
          .map((pluginBuilder) =>
              AddButtonActionWrapper(pluginBuilder: pluginBuilder))
          .toList(),
    );

    // Import
    actions.addAll(
      getIt<PluginSandbox>()
          .builders
          .whereType<DocumentPluginBuilder>()
          .map((pluginBuilder) =>
              ImportActionWrapper(pluginBuilder: pluginBuilder))
          .toList(),
    );

    return PopoverActionList<PopoverAction>(
      direction: PopoverDirection.bottomWithLeftAligned,
      actions: actions,
      offset: const Offset(0, 8),
      buildChild: (controller) {
        return SizedBox(
          width: 22,
          child: InkWell(
            onTap: () => controller.show(),
            child: FlowyHover(
              style: HoverStyle(
                hoverColor: AFThemeExtension.of(context).greySelect,
              ),
              builder: (context, onHover) => const FlowySvg(
                name: 'home/add',
              ),
            ),
          ),
        );
      },
      onSelected: (action, controller) {
        if (action is AddButtonActionWrapper) {
          onSelected(action.pluginBuilder, null);
        }
        if (action is ImportActionWrapper) {
          showImportPanel(context, (document) {
            if (document == null) {
              return;
            }
            onSelected(action.pluginBuilder, document);
          });
        }
        controller.close();
      },
    );
  }
}

class AddButtonActionWrapper extends ActionCell {
  final PluginBuilder pluginBuilder;

  AddButtonActionWrapper({required this.pluginBuilder});

  @override
  Widget? leftIcon(Color iconColor) => FlowySvg(name: pluginBuilder.menuIcon);

  @override
  String get name => pluginBuilder.menuName;

  PluginType get pluginType => pluginBuilder.pluginType;
}

class ImportActionWrapper extends ActionCell {
  final DocumentPluginBuilder pluginBuilder;

  ImportActionWrapper({
    required this.pluginBuilder,
  });

  @override
  Widget? leftIcon(Color iconColor) => const FlowySvg(
        name: 'editor/import',
      );

  @override
  String get name => LocaleKeys.moreAction_import.tr();
}
