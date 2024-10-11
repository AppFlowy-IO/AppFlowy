import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/constants.dart';
import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // copy link to block
  group('copy link to block:', () {
    testWidgets('copy link to check if the clipboard has the correct content',
        (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // open getting started page
      await tester.openPage(Constants.gettingStartedPageName);
      await tester.editor.copyLinkToBlock([0]);
      await tester.pumpAndSettle(Durations.short1);

      // check the clipboard
      final content = await Clipboard.getData(Clipboard.kTextPlain);
      expect(
        content?.text,
        matches(
          r'^https:\/\/appflowy\.com\/app\/[a-f0-9-]{36}\/[a-f0-9-]{36}\?blockId=[A-Za-z0-9_-]+$',
        ),
      );
    });

    testWidgets('copy link to block and paste it in doc', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // open getting started page
      await tester.openPage(Constants.gettingStartedPageName);
      await tester.editor.copyLinkToBlock([0]);

      // create a new page and paste it
      const pageName = 'copy link to block';
      await tester.createNewPageInSpace(
        spaceName: Constants.generalSpaceName,
        layout: ViewLayoutPB.Document,
        pageName: pageName,
      );

      // paste the link to the new page
      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.paste();
      await tester.pumpAndSettle();

      // check the content of the block
      final node = tester.editor.getNodeAtPath([0]);
      final delta = node.delta!;
      final insert = (delta.first as TextInsert).text;
      final attributes = delta.first.attributes;
      expect(insert, MentionBlockKeys.mentionChar);
      final mention =
          attributes?[MentionBlockKeys.mention] as Map<String, dynamic>;
      expect(mention[MentionBlockKeys.type], MentionType.page.name);
      expect(mention[MentionBlockKeys.blockId], isNotNull);
      expect(mention[MentionBlockKeys.pageId], isNotNull);
      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.textContaining(
            Constants.gettingStartedPageName,
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.textContaining(
            // the pasted block content is 'Welcome to AppFlowy'
            'Welcome to AppFlowy',
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
    });
  });
}
