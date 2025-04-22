import 'package:appflowy/workspace/presentation/settings/shared/settings_category_spacer.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_header.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SettingsBody extends StatelessWidget {
  const SettingsBody({
    super.key,
    required this.title,
    this.description,
    this.descriptionBuilder,
    this.autoSeparate = true,
    required this.children,
  });

  final String title;
  final String? description;
  final WidgetBuilder? descriptionBuilder;
  final bool autoSeparate;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsHeader(
            title: title,
            description: description,
            descriptionBuilder: descriptionBuilder,
          ),
          SettingsCategorySpacer(),
          Flexible(
            child: SeparatedColumn(
              mainAxisSize: MainAxisSize.min,
              separatorBuilder: () => autoSeparate
                  ? const SettingsCategorySpacer()
                  : const SizedBox.shrink(),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
