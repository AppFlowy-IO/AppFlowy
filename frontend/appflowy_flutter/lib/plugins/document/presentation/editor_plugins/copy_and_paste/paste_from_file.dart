import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_util.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:cross_file/cross_file.dart';

extension PasteFromFile on EditorState {
  Future<void> dropFiles(
    Node dropNode,
    List<XFile> files,
    String documentId,
    bool isLocalMode,
  ) async {
    for (final file in files) {
      String? path;
      FileUrlType? type;
      if (isLocalMode) {
        path = await saveFileToLocalStorage(file.path);
        type = FileUrlType.local;
      } else {
        (path, _) = await saveFileToCloudStorage(file.path, documentId);
        type = FileUrlType.cloud;
      }

      if (path == null) {
        continue;
      }

      final t = transaction
        ..insertNode(
          dropNode.path,
          fileNode(
            url: path,
            type: type,
            name: file.name,
          ),
        );
      await apply(t);
    }
  }
}
