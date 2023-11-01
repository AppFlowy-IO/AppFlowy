import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IconPickerPage extends StatefulWidget {
  const IconPickerPage({
    super.key,
    required this.id,
  });

  /// view id
  final String id;

  @override
  State<IconPickerPage> createState() => _IconPickerPageState();
}

class _IconPickerPageState extends State<IconPickerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const FlowyText.semibold(
          'Page icon',
          fontSize: 14.0,
        ),
        leading: AppBarBackButton(
          onTap: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: FlowyIconPicker(
          onSelected: (_, emoji) {
            ViewBackendService.updateViewIcon(
              viewId: widget.id,
              viewIcon: emoji,
            );
            context.pop();
          },
        ),
      ),
    );
  }
}
