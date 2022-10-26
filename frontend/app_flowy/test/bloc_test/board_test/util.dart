import 'package:app_flowy/plugins/board/board.dart';
import 'package:app_flowy/workspace/application/app/app_service.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';

import '../grid_test/util.dart';

class AppFlowyBoardTest {
  final AppFlowyGridTest _inner;
  late ViewPB boardView;
  AppFlowyBoardTest(AppFlowyGridTest unitTest) : _inner = unitTest;

  static Future<AppFlowyBoardTest> ensureInitialized() async {
    final inner = await AppFlowyGridTest.ensureInitialized();
    return AppFlowyBoardTest(inner);
  }

  Future<void> createTestBoard() async {
    final app = await _inner.unitTest.createTestApp();
    final builder = BoardPluginBuilder();
    final result = await AppService().createView(
      appId: app.id,
      name: "Test Board",
      dataFormatType: builder.dataFormatType,
      pluginType: builder.pluginType,
      layoutType: builder.layoutType!,
    );
    await result.fold(
      (view) async {
        boardView = view;
      },
      (error) {},
    );
  }
}

Future<void> boardResponseFuture() {
  return Future.delayed(boardResponseDuration(milliseconds: 200));
}

Duration boardResponseDuration({int milliseconds = 200}) {
  return Duration(milliseconds: milliseconds);
}
