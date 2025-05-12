import 'package:appflowy/plugins/ai_chat/presentation/chat_page/chat_animation_list_widget.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ai_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('chat page:', () {
    testWidgets('send messages with default messages', (tester) async {
      skipAIChatWelcomePage = true;

      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a chat page
      final pageName = 'Untitled';
      await tester.createNewPageWithNameUnderParent(
        name: pageName,
        layout: ViewLayoutPB.Chat,
        openAfterCreated: false,
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      final userId = '457037009907617792';
      final user = User(id: userId, lastName: 'Lucas');
      final aiUserId = '0';
      final aiUser = User(id: aiUserId, lastName: 'AI');

      await tester.loadDefaultMessages(
        [
          Message.text(
            id: '1746776401',
            text: 'How to use Kanban to manage tasks?',
            author: user,
            createdAt: DateTime.now().add(const Duration(seconds: 1)),
          ),
          Message.text(
            id: '1746776401_ans',
            text:
                'I couldn’t find any relevant information in the sources you selected. Please try asking a different question',
            author: aiUser,
            createdAt: DateTime.now().add(const Duration(seconds: 2)),
          ),
          Message.text(
            id: '1746776402',
            text: 'How to use Kanban to manage tasks?',
            author: user,
            createdAt: DateTime.now().add(const Duration(seconds: 3)),
          ),
          Message.text(
            id: '1746776402_ans',
            text:
                'I couldn’t find any relevant information in the sources you selected. Please try asking a different question',
            author: aiUser,
            createdAt: DateTime.now().add(const Duration(seconds: 4)),
          ),
        ].reversed.toList(),
      );
      await tester.pumpAndSettle(Duration(seconds: 1));

      // start chat
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
      await tester.pumpAndSettle(Duration(seconds: 1));

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
      await tester.pumpAndSettle(Duration(seconds: 1));

      final chatBloc = tester.getCurrentChatBloc();
      expect(chatBloc.chatController.messages.length, equals(6));
    });

    testWidgets('send messages without default messages', (tester) async {
      skipAIChatWelcomePage = true;

      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a chat page
      final pageName = 'Untitled';
      await tester.createNewPageWithNameUnderParent(
        name: pageName,
        layout: ViewLayoutPB.Chat,
        openAfterCreated: false,
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      final userId = '457037009907617792';
      final user = User(id: userId, lastName: 'Lucas');
      final aiUserId = '0';
      final aiUser = User(id: aiUserId, lastName: 'AI');

      // start chat
      int messageId = 1;

      // round 1
      {
        // send a message
        await tester.sendUserMessage(
          Message.text(
            id: messageId.toString(),
            text: 'How to use AppFlowy?',
            author: user,
            createdAt: DateTime.now(),
          ),
        );
        await tester.pumpAndSettle(Duration(seconds: 1));

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
        await tester.pumpAndSettle(Duration(seconds: 1));
        messageId++;
      }

      // round 2
      {
        // send a message
        await tester.sendUserMessage(
          Message.text(
            id: messageId.toString(),
            text: 'How to use AppFlowy?',
            author: user,
            createdAt: DateTime.now(),
          ),
        );
        await tester.pumpAndSettle(Duration(seconds: 1));

        // receive a message
        await tester.receiveAIMessage(
          Message.text(
            id: '${messageId}_ans',
            text:
                'I couldn’t find any relevant information in the sources you selected. Please try asking a different question',
            author: aiUser,
            createdAt: DateTime.now(),
          ),
        );
        await tester.pumpAndSettle(Duration(seconds: 1));
        messageId++;
      }

      // round 3
      {
        // send a message
        await tester.sendUserMessage(
          Message.text(
            id: messageId.toString(),
            text: 'What document formatting options are available?',
            author: user,
            createdAt: DateTime.now(),
          ),
        );
        await tester.pumpAndSettle(Duration(seconds: 1));

        // receive a message
        await tester.receiveAIMessage(
          Message.text(
            id: '${messageId}_ans',
            text:
                '# AppFlowy Document Formatting\n- Basic formatting: Bold, italic, underline, strikethrough\n- Headings: 6 levels of headings for structuring content\n- Lists: Bullet points, numbered lists, and checklists\n- Code blocks: Format text as code with syntax highlighting\n- Tables: Create and format data tables\n- Embedded content: Add images, files, and other rich media',
            author: aiUser,
            createdAt: DateTime.now(),
          ),
        );
        await tester.pumpAndSettle(Duration(seconds: 1));
        messageId++;
      }

      // round 4
      {
        // send a message
        await tester.sendUserMessage(
          Message.text(
            id: messageId.toString(),
            text: 'How do I export my data from AppFlowy?',
            author: user,
            createdAt: DateTime.now(),
          ),
        );
        await tester.pumpAndSettle(Duration(seconds: 1));

        // receive a message
        await tester.receiveAIMessage(
          Message.text(
            id: '${messageId}_ans',
            text:
                '# Exporting from AppFlowy\n- Export documents in multiple formats: Markdown, HTML, PDF\n- Export databases as CSV or Excel files\n- Batch export entire workspaces for backup\n- Use the export menu (three dots → Export) on any page\n- Exported files maintain most formatting and structure',
            author: aiUser,
            createdAt: DateTime.now(),
          ),
        );
        await tester.pumpAndSettle(Duration(seconds: 1));
        messageId++;
      }

      // round 5
      {
        // send a message
        await tester.sendUserMessage(
          Message.text(
            id: messageId.toString(),
            text: 'Is there a mobile version of AppFlowy?',
            author: user,
            createdAt: DateTime.now(),
          ),
        );
        await tester.pumpAndSettle(Duration(seconds: 1));

        // receive a message
        await tester.receiveAIMessage(
          Message.text(
            id: '${messageId}_ans',
            text:
                '# AppFlowy on Mobile\n- Yes, AppFlowy is available for iOS and Android devices\n- Download from the App Store or Google Play Store\n- Mobile app includes core functionality: document editing, databases, and boards\n- Offline mode allows working without internet connection\n- Sync automatically when you reconnect\n- Responsive design adapts to different screen sizes',
            author: aiUser,
            createdAt: DateTime.now(),
          ),
        );
        await tester.pumpAndSettle(Duration(seconds: 1));
        messageId++;
      }

      final chatBloc = tester.getCurrentChatBloc();
      expect(chatBloc.chatController.messages.length, equals(10));
    });
  });
}
