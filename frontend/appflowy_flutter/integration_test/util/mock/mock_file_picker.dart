import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:file_picker/src/file_picker.dart' as fp;
import 'package:path/path.dart' as p;
import '../util.dart';

class MockFilePicker implements FilePickerService {
  MockFilePicker({
    required this.mockPath,
  });

  final String mockPath;

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
    throw UnimplementedError();
  }
}

Future<void> mockGetDirectoryPath(String? name) async {
  final dir = await TestFolder.testLocation(name);
  getIt.unregister<FilePickerService>();
  getIt.registerFactory<FilePickerService>(
    () => MockFilePicker(
      mockPath: dir.path,
    ),
  );
  return;
}

Future<String> mockSaveFilePath(String? name, String fileName) async {
  final dir = await TestFolder.testLocation(name);
  final path = p.join(dir.path, fileName);
  getIt.unregister<FilePickerService>();
  getIt.registerFactory<FilePickerService>(
    () => MockFilePicker(
      mockPath: path,
    ),
  );
  return path;
}
