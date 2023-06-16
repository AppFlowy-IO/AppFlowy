import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/migration/editor_migration.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:appflowy/workspace/application/settings/share/import_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/header/import/import_type.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/container.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path/path.dart' as p;

typedef ImportCallback = void Function(
  ImportType type,
  String name,
  List<int>? document,
);

Future<void> showImportPanel(
  String parentViewId,
  BuildContext context,
  ImportCallback callback,
) async {
  await FlowyOverlay.show(
    context: context,
    builder: (context) => FlowyDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: FlowyText.semibold(
        LocaleKeys.moreAction_import.tr(),
        fontSize: 20,
        color: Theme.of(context).colorScheme.tertiary,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 20.0,
        ),
        child: ImportPanel(
          parentViewId: parentViewId,
          importCallback: callback,
        ),
      ),
    ),
  );
}

class ImportPanel extends StatelessWidget {
  const ImportPanel({
    super.key,
    required this.parentViewId,
    required this.importCallback,
  });

  final String parentViewId;
  final ImportCallback importCallback;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.7;
    final height = width * 0.5;
    return FlowyContainer(
      Theme.of(context).colorScheme.surface,
      height: height,
      width: width,
      child: GridView.count(
        childAspectRatio: 1 / .2,
        crossAxisCount: 2,
        children: ImportType.values
            .where((element) => element.enableOnRelease)
            .map(
              (e) => Card(
                child: FlowyButton(
                  leftIcon: e.icon(context),
                  leftIconSize: const Size.square(20),
                  text: FlowyText.medium(
                    e.toString(),
                    fontSize: 15,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    await _importFile(parentViewId, e);
                    if (context.mounted) {
                      FlowyOverlay.pop(context);
                    }
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _importFile(String parentViewId, ImportType importType) async {
    final result = await getIt<FilePickerService>().pickFiles(
      type: FileType.custom,
      allowMultiple: importType.allowMultiSelect,
      allowedExtensions: importType.allowedExtensions,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    for (final file in result.files) {
      final path = file.path;
      if (path == null) {
        continue;
      }
      final data = await File(path).readAsString();
      final name = p.basenameWithoutExtension(path);

      switch (importType) {
        case ImportType.markdownOrText:
        case ImportType.historyDocument:
          final bytes = _documentDataFrom(importType, data);
          if (bytes != null) {
            await ImportBackendService.importData(
              bytes,
              name,
              parentViewId,
              ImportTypePB.HistoryDocument,
            );
          }
          break;
        case ImportType.historyDatabase:
          await ImportBackendService.importData(
            utf8.encode(data),
            name,
            parentViewId,
            ImportTypePB.HistoryDatabase,
          );
          break;
        case ImportType.databaseRawData:
          await ImportBackendService.importData(
            utf8.encode(data),
            name,
            parentViewId,
            ImportTypePB.RawDatabase,
          );
          break;
        case ImportType.databaseCSV:
          await ImportBackendService.importData(
            utf8.encode(data),
            name,
            parentViewId,
            ImportTypePB.CSV,
          );
          break;
        default:
          assert(false, 'Unsupported Type $importType');
      }
    }
  }
}

Uint8List? _documentDataFrom(ImportType importType, String data) {
  switch (importType) {
    case ImportType.markdownOrText:
      final document = markdownToDocument(data);
      return DocumentDataPBFromTo.fromDocument(document)?.writeToBuffer();
    case ImportType.historyDocument:
      final document = EditorMigration.migrateDocument(data);
      return DocumentDataPBFromTo.fromDocument(document)?.writeToBuffer();
    default:
      assert(false, 'Unsupported Type $importType');
      return null;
  }
}
