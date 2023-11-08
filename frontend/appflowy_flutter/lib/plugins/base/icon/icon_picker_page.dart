import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IconPickerPage extends StatefulWidget {
  const IconPickerPage({
    super.key,
    required this.onSelected,
  });

  final void Function(EmojiPickerResult) onSelected;

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
          onSelected: widget.onSelected,
        ),
      ),
    );
  }
}
