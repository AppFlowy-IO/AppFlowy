import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ImagePickerPage extends StatefulWidget {
  const ImagePickerPage({
    super.key,
    // required this.onSelected,
  });

  // final void Function(EmojiPickerResult) onSelected;

  @override
  State<ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
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
        child: UploadImageMenu(
          onSubmitted: (_) {},
          onUpload: (_) {},
        ),
      ),
    );
  }
}
