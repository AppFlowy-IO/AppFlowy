import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/import.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';

class ImportAppFlowyData extends StatelessWidget {
  const ImportAppFlowyData({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImportAppFlowyDataButton();
  }
}

class ImportAppFlowyDataButton extends StatefulWidget {
  const ImportAppFlowyDataButton({super.key});

  @override
  State<ImportAppFlowyDataButton> createState() =>
      _ImportAppFlowyDataButtonState();
}

class _ImportAppFlowyDataButtonState extends State<ImportAppFlowyDataButton> {
  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      text: FlowyText(LocaleKeys.settings_menu_importAppFlowyData.tr()),
      onTap: () async {
        final path = await getIt<FilePickerService>().getDirectoryPath();
        if (path == null) {
          return;
        }
        if (!mounted) {
          return;
        }

        final payload = ImportAppFlowyDataPB.create()..path = path;
        final result =
            await FolderEventImportAppFlowyDataFolder(payload).send();
        result.fold((l) => null, (err) {
          Log.error(err);
        });
      },
    );
  }
}
