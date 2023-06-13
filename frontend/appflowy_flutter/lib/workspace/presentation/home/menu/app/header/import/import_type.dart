import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';

enum ImportType {
  historyDocument,
  historyDatabase,
  markdownOrText,
  databaseCSV;

  @override
  String toString() {
    switch (this) {
      case ImportType.historyDocument:
        return LocaleKeys.importPanel_documentFromV010.tr();
      case ImportType.historyDatabase:
        return LocaleKeys.importPanel_databaseFromV010.tr();
      case ImportType.markdownOrText:
        return LocaleKeys.importPanel_textAndMarkdown.tr();
      case ImportType.databaseCSV:
        return LocaleKeys.importPanel_csv.tr();
    }
  }

  WidgetBuilder get icon => (context) {
        final String name;
        switch (this) {
          case ImportType.historyDocument:
            name = 'editor/board';
          case ImportType.historyDatabase:
            name = 'editor/documents';
          case ImportType.databaseCSV:
            name = 'editor/board';
          case ImportType.markdownOrText:
            name = 'editor/text';
        }
        return FlowySvg(
          name: name,
        );
      };

  List<String> get allowedExtensions {
    switch (this) {
      case ImportType.historyDocument:
        return ['afdoc'];
      case ImportType.historyDatabase:
        return ['afdb'];
      case ImportType.markdownOrText:
        return ['md', 'txt'];
      case ImportType.databaseCSV:
        return ['csv'];
    }
  }

  bool get allowMultiSelect {
    switch (this) {
      case ImportType.historyDocument:
      case ImportType.databaseCSV:
      case ImportType.historyDatabase:
      case ImportType.markdownOrText:
        return true;
    }
  }
}
