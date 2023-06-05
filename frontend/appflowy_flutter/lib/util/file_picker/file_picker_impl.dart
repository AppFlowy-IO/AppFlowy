import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:file_picker/file_picker.dart' as fp;

class FilePicker implements FilePickerService {
  @override
  Future<String?> getDirectoryPath({final String? title}) {
    return fp.FilePicker.platform.getDirectoryPath();
  }

  @override
  Future<FilePickerResult?> pickFiles({
    final String? dialogTitle,
    final String? initialDirectory,
    final fp.FileType type = fp.FileType.any,
    final List<String>? allowedExtensions,
    final Function(fp.FilePickerStatus p1)? onFileLoading,
    final bool allowCompression = true,
    final bool allowMultiple = false,
    final bool withData = false,
    final bool withReadStream = false,
    final bool lockParentWindow = false,
  }) async {
    final result = await fp.FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
      onFileLoading: onFileLoading,
      allowCompression: allowCompression,
      allowMultiple: allowMultiple,
      withData: withData,
      withReadStream: withReadStream,
      lockParentWindow: lockParentWindow,
    );
    return FilePickerResult(result?.files ?? []);
  }
}
