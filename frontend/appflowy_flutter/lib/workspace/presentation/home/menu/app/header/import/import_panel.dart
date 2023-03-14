import 'dart:io';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/container.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

typedef ImportCallback = void Function(Document? document);

Future<void> showImportPanel(
  BuildContext context,
  ImportCallback callback,
) async {
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: FlowyText.semibold(
          LocaleKeys.moreAction_import.tr(),
          fontSize: 20,
        ),
        content: _ImportPanel(importCallback: callback),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 20.0,
        ),
      );
    },
  );
}

enum _ImportType {
  markdownOrText;

  @override
  String toString() {
    switch (this) {
      case _ImportType.markdownOrText:
        return 'Text & Markdown';
      default:
        assert(false, 'Unsupported Type $this');
        return '';
    }
  }

  Widget? get icon {
    switch (this) {
      case _ImportType.markdownOrText:
        return svgWidget('editor/documents');
      default:
        assert(false, 'Unsupported Type $this');
        return null;
    }
  }

  List<String> get allowedExtensions {
    switch (this) {
      case _ImportType.markdownOrText:
        return ['md', 'txt'];
      default:
        assert(false, 'Unsupported Type $this');
        return [];
    }
  }
}

class _ImportPanel extends StatefulWidget {
  const _ImportPanel({
    required this.importCallback,
  });

  final ImportCallback importCallback;

  @override
  State<_ImportPanel> createState() => _ImportPanelState();
}

class _ImportPanelState extends State<_ImportPanel> {
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
        children: _ImportType.values.map(
          (e) {
            return Card(
              child: FlowyButton(
                leftIcon: e.icon,
                leftIconSize: const Size.square(20),
                text: FlowyText.medium(
                  e.toString(),
                  fontSize: 15,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  await _importFile(e);
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Future<void> _importFile(_ImportType importType) async {
    final result = await getIt<FilePickerService>().pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: importType.allowedExtensions,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final path = result.files.single.path!;
    final plainText = await File(path).readAsString();

    switch (importType) {
      case _ImportType.markdownOrText:
        final document = markdownToDocument(plainText);
        widget.importCallback(document);
        break;
      default:
        assert(false, 'Unsupported Type $importType');
        widget.importCallback(null);
    }
  }
}
