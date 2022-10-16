import 'package:app_flowy/plugins/grid/grid.dart';
import 'package:app_flowy/workspace/application/app/app_service.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';

import '../../util.dart';

/// Create a empty Grid for test
class AppFlowyGridTest {
  // ignore: unused_field
  final AppFlowyUnitTest _inner;
  late ViewPB gridView;
  AppFlowyGridTest(AppFlowyUnitTest unitTest) : _inner = unitTest;

  static Future<AppFlowyGridTest> ensureInitialized() async {
    final inner = await AppFlowyUnitTest.ensureInitialized();
    final test = AppFlowyGridTest(inner);
    await test._createTestGrid();
    return test;
  }

  Future<void> _createTestGrid() async {
    final app = await _inner.createTestApp();
    final builder = GridPluginBuilder();
    final result = await AppService().createView(
      appId: app.id,
      name: "Test Grid",
      dataType: builder.dataType,
      pluginType: builder.pluginType,
      layoutType: builder.layoutType!,
    );
    result.fold(
      (view) => gridView = view,
      (error) {},
    );
  }
}

Future<void> gridBlocResponseFuture({int millseconds = 100}) {
  return Future.delayed(gridBlocResponseDuration(millseconds: millseconds));
}

Duration gridBlocResponseDuration({int millseconds = 100}) {
  return Duration(milliseconds: millseconds);
}
