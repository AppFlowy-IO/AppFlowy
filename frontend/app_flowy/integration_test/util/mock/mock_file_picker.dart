import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/util/file_picker/file_picker_impl.dart';
import 'package:app_flowy/util/file_picker/file_picker_service.dart';

import '../util.dart';

class MockFilePicker extends FilePicker {
  MockFilePicker({
    required this.mockPath,
  });

  final String mockPath;

  @override
  Future<String?> getDirectoryPath({String? title}) {
    return Future.value(mockPath);
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
