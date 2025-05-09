import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ai_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('chat page:', () {
    testWidgets('send messages', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a chat page
      final pageName = 'Untitled';
      await tester.createNewPageWithNameUnderParent(
        name: pageName,
        layout: ViewLayoutPB.Chat,
        openAfterCreated: false,
      );

      final userId = '457037009907617792';
      final user = User(id: userId, lastName: 'Lucas');
      final aiUserId = '457037009907617793';
      final aiUser = User(id: aiUserId, lastName: 'AI');

      // focus on the chat page
      final int messageId = 1;

      // send a message
      await tester.sendUserMessage(
        Message.text(
          id: messageId.toString(),
          text: 'How to use AppFlowy?',
          author: user,
          createdAt: DateTime.now(),
        ),
      );

      // receive a message
      await tester.receiveAIMessage(
        Message.text(
          id: '${messageId}_ans',
          text: '''# How to Use AppFlowy
- Download and install AppFlowy from the official website (appflowy.io) or through app stores for your operating system (Windows, macOS, Linux, or mobile)
- Create an account or sign in when you first launch the app
- The main interface shows your workspace with a sidebar for navigation and a content area''',
          author: aiUser,
          createdAt: DateTime.now(),
        ),
      );

      await tester.wait(100000);
    });
  });
}
