import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/share/import_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/import.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class NotionImporter extends StatelessWidget {
  const NotionImporter({required this.filePath, super.key});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40, maxHeight: 200),
      child: FutureBuilder(
        future: _uploadFile(),
        builder: (context, snapshots) {
          if (!snapshots.hasData) {
            return const _Uploading();
          }

          if (snapshots.hasError) {
            return _UploadError(error: snapshots.error as FlowyError);
          }

          return const _UploadSuccess();
        },
      ),
    );
  }

  Future<FlowyResult<void, FlowyError>> _uploadFile() async {
    final importResult = await ImportBackendService.importZipFiles(
      [ImportZipPB()..filePath = filePath],
    );

    return importResult;
  }
}

class _UploadSuccess extends StatelessWidget {
  const _UploadSuccess();

  @override
  Widget build(BuildContext context) {
    return FlowyText(
      fontSize: 16,
      LocaleKeys.settings_common_uploadNotionSuccess.tr(),
      maxLines: 10,
    );
  }
}

class _Uploading extends StatelessWidget {
  const _Uploading();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator.adaptive(),
            const VSpace(12),
            FlowyText(
              fontSize: 16,
              LocaleKeys.settings_common_uploadingFile.tr(),
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadError extends StatelessWidget {
  const _UploadError({required this.error});

  final FlowyError error;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
