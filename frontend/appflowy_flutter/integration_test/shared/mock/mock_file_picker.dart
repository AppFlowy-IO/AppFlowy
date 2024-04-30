import 'package:appflowy/startup/startup.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';

class MockFilePicker implements FilePickerService {
  MockFilePicker({
    this.mockPath = '',
    this.mockPaths = const [],
  });

  final String mockPath;
  final List<String> mockPaths;

  @override
  Future<String?> getDirectoryPath({String? title}) => Future.value(mockPath);

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool lockParentWindow = false,
  }) =>
      Future.value(mockPath);

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus p1)? onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
  }) {
    final platformFiles =
        mockPaths.map((e) => PlatformFile(path: e, name: '', size: 0)).toList();
    return Future.value(FilePickerResult(platformFiles));
  }
}

Future<void> mockGetDirectoryPath(String path) async {
  getIt.unregister<FilePickerService>();
  getIt.registerFactory<FilePickerService>(
    () => MockFilePicker(mockPath: path),
  );
}

Future<String> mockSaveFilePath(String path) async {
  getIt.unregister<FilePickerService>();
  getIt.registerFactory<FilePickerService>(
    () => MockFilePicker(mockPath: path),
  );
  return path;
}

List<String> mockPickFilePaths({required List<String> paths}) {
  getIt.unregister<FilePickerService>();
  getIt.registerFactory<FilePickerService>(
    () => MockFilePicker(mockPaths: paths),
  );
  return paths;
}
