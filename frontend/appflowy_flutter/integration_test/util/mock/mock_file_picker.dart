import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/file_picker/file_picker_impl.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';

import '../util.dart';

class MockFilePicker extends FilePicker {
  MockFilePicker({
    required this.mockPath,
  });

  final String mockPath;

  @override
  Future<String?> getDirectoryPath({final String? title}) {
    return Future.value(mockPath);
  }
}

Future<void> mockGetDirectoryPath(final String? name) async {
  final dir = await TestFolder.testLocation(name);
  getIt.unregister<FilePickerService>();
  getIt.registerFactory<FilePickerService>(
    () => MockFilePicker(
      mockPath: dir.path,
    ),
  );
  return;
}
