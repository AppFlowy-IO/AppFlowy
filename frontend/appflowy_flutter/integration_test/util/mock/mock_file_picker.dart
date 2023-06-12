import 'dart:io';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path/path.dart' as p;
import '../util.dart';

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

Future<List<String>> mockPickFilePaths(
  List<String> fileNames, {
  String? name,
  String? customPath,
}) async {
  late final Directory dir;
  if (customPath != null) {
    dir = Directory(customPath);
  } else {
    dir = await TestFolder.testLocation(name);
  }
  final paths = fileNames.map((e) => p.join(dir.path, e)).toList();
  getIt.unregister<FilePickerService>();
  getIt.registerFactory<FilePickerService>(
    () => MockFilePicker(
      mockPaths: paths,
    ),
  );
  return paths;
}
