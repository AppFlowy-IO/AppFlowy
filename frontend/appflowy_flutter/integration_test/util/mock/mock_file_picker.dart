import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:file_picker/file_picker.dart' as fp;

class MockFilePicker implements FilePickerService {
  MockFilePicker({
    this.mockPath = '',
    this.mockPaths = const [],
  });

  final String mockPath;
  final List<String> mockPaths;

  @override
  Future<String?> getDirectoryPath({String? title}) {
    return Future.value(mockPath);
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    fp.FileType type = fp.FileType.any,
    List<String>? allowedExtensions,
    bool lockParentWindow = false,
  }) {
    return Future.value(mockPath);
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    fp.FileType type = fp.FileType.any,
    List<String>? allowedExtensions,
    Function(fp.FilePickerStatus p1)? onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
  }) {
    final platformFiles = mockPaths
        .map((e) => fp.PlatformFile(path: e, name: '', size: 0))
        .toList();
    return Future.value(
      FilePickerResult(
        platformFiles,
      ),
    );
  }
}

Future<void> mockGetDirectoryPath(
  String path,
) async {
  getIt.unregister<FilePickerService>();
  getIt.registerFactory<FilePickerService>(
    () => MockFilePicker(
      mockPath: path,
    ),
  );
  return;
}

Future<String> mockSaveFilePath(
  String path,
) async {
  getIt.unregister<FilePickerService>();
  getIt.registerFactory<FilePickerService>(
    () => MockFilePicker(
      mockPath: path,
    ),
  );
  return path;
}

Future<List<String>> mockPickFilePaths({
  required List<String> paths,
}) async {
  // late final Directory dir;
  // if (customPath != null) {
  //   dir = Directory(customPath);
  // } else {
  //   dir = await TestFolder.testLocation(applicationDataPath, name);
  // }
  // final paths = fileNames.map((e) => p.join(dir.path, e)).toList();
  getIt.unregister<FilePickerService>();
  getIt.registerFactory<FilePickerService>(
    () => MockFilePicker(
      mockPaths: paths,
    ),
  );
  return paths;
}
