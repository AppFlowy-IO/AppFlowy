import 'package:file_picker/file_picker.dart';

class FilePickerResult {
  const FilePickerResult(this.files);

  /// Picked files.
  final List<PlatformFile> files;
}

/// Abstract file picker as a service to implement dependency injection.
abstract class FilePickerService {
  Future<String?> getDirectoryPath({
    final String? title,
  }) async =>
      throw UnimplementedError('getDirectoryPath() has not been implemented.');

  Future<FilePickerResult?> pickFiles({
    final String? dialogTitle,
    final String? initialDirectory,
    final FileType type = FileType.any,
    final List<String>? allowedExtensions,
    final Function(FilePickerStatus)? onFileLoading,
    final bool allowCompression = true,
    final bool allowMultiple = false,
    final bool withData = false,
    final bool withReadStream = false,
    final bool lockParentWindow = false,
  }) async =>
      throw UnimplementedError('pickFiles() has not been implemented.');
}
