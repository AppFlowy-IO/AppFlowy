import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/plugins/base/icon_picker.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmojiPickerPage extends StatefulWidget {
  const EmojiPickerPage({
    super.key,
    required this.id,
  });

  /// view id
  final String id;

  @override
  State<EmojiPickerPage> createState() => _EmojiPickerPageState();
}

class _EmojiPickerPageState extends State<EmojiPickerPage> {
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
        actions: const [],
      ),
      body: SafeArea(
        child: FlowyIconPicker(
          onSelected: (_, __) {},
        ),
      ),
    );
  }
}
