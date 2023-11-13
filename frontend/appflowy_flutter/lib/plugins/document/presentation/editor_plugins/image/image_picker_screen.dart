import 'package:appflowy/plugins/document/presentation/editor_plugins/image/flowy_image_picker.dart';
import 'package:flutter/material.dart';

class MobileImagePickerScreen extends StatelessWidget {
  static const routeName = '/image_picker';

  const MobileImagePickerScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const ImagePickerPage();
  }
}
