import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

class UploadImageFileWidget extends StatelessWidget {
  const UploadImageFileWidget({
    super.key,
    required this.onPickFile,
    this.allowedExtensions = const ['jpg', 'png', 'jpeg'],
  });

  final void Function(String? path) onPickFile;
  final List<String> allowedExtensions;

  @override
  Widget build(BuildContext context) {
    return FlowyHover(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) async {
          final result = await getIt<FilePickerService>().pickFiles(
            dialogTitle: '',
            allowMultiple: false,
            type: FileType.image,
            allowedExtensions: allowedExtensions,
          );
          onPickFile(result?.files.firstOrNull?.path);
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.surfaceVariant,
              width: 1.0,
            ),
          ),
          child: FlowyText(
            LocaleKeys.document_imageBlock_upload_placeholder.tr(),
          ),
        ),
      ),
    );
  }
}
