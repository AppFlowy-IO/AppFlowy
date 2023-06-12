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
        return 'Document from v0.1';
      case ImportType.historyDatabase:
        return 'Database from v0.1';
      case ImportType.markdownOrText:
        return 'Text & Markdown';
      case ImportType.databaseCSV:
        return 'CSV';
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
