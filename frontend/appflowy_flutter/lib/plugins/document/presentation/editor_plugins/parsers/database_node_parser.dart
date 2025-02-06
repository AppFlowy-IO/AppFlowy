import 'package:appflowy/plugins/document/presentation/editor_plugins/database/database_view_block_component.dart';
import 'package:appflowy/workspace/application/settings/share/export_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

abstract class DatabaseNodeParser extends NodeParser {
  DatabaseNodeParser(this.files, this.dirPath);

  final List<Future<ArchiveFile>> files;
  final String dirPath;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final String viewId = node.attributes['view_id'] ?? '';
    if (viewId.isEmpty) return '';
    files.add(_convertDatabaseToCSV(viewId));
    return '''[](${p.join(dirPath, '$viewId.csv')})''';
  }

  Future<ArchiveFile> _convertDatabaseToCSV(String viewId) async {
    final result = await BackendExportService.exportDatabaseAsCSV(viewId);
    final filePath = p.join(dirPath, '$viewId.csv');
    ArchiveFile file = ArchiveFile.string(filePath, '');
    result.fold(
      (s) => file = ArchiveFile.string(filePath, s.data),
      (f) => Log.error('convertDatabaseToCSV error with $viewId, error: $f'),
    );
    return file;
  }
}

class GridNodeParser extends DatabaseNodeParser {
  GridNodeParser(super.files, super.dirPath);

  @override
  String get id => DatabaseBlockKeys.gridType;
}

class BoardNodeParser extends DatabaseNodeParser {
  BoardNodeParser(super.files, super.dirPath);

  @override
  String get id => DatabaseBlockKeys.boardType;
}

class CalendarNodeParser extends DatabaseNodeParser {
  CalendarNodeParser(super.files, super.dirPath);

  @override
  String get id => DatabaseBlockKeys.calendarType;
}
