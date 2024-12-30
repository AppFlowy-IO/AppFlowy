import 'package:appflowy/plugins/ai_chat/chat.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

import '../../util.dart';

class AppFlowyChatTest {
  AppFlowyChatTest({required this.unitTest});

  final AppFlowyUnitTest unitTest;

  static Future<AppFlowyChatTest> ensureInitialized() async {
    final inner = await AppFlowyUnitTest.ensureInitialized();
    return AppFlowyChatTest(unitTest: inner);
  }

  Future<ViewPB> createChat() async {
    final app = await unitTest.createWorkspace();
    final builder = AIChatPluginBuilder();
    return ViewBackendService.createView(
      parentViewId: app.id,
      name: "Test Chat",
      layoutType: builder.layoutType,
      openAfterCreate: true,
    ).then((result) {
      return result.fold(
        (view) async {
          return view;
        },
        (error) {
          throw Exception();
        },
      );
    });
  }
}

Future<void> boardResponseFuture() {
  return Future.delayed(boardResponseDuration());
}

Duration boardResponseDuration({int milliseconds = 200}) {
  return Duration(milliseconds: milliseconds);
}
