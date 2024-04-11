import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('test editing link in document', () {
    late MockUrlLauncher mock;

    setUp(() {
      mock = MockUrlLauncher();
      UrlLauncherPlatform.instance = mock;
    });

    testWidgets('insert/edit/open link', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent();

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      // insert a inline page
      const link = 'AppFlowy';
      await tester.ime.insertText(link);
      await tester.editor.updateSelection(
        Selection.single(path: [0], startOffset: 0, endOffset: link.length),
      );

      // tap the link button
      final linkButton = find.byTooltip(
        'Link',
      );
      await tester.tapButton(linkButton);
      expect(find.text('Add your link', findRichText: true), findsOneWidget);

      // input the link
      const url = 'https://appflowy.io';
      final textField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration!.hintText == 'URL',
      );
      await tester.enterText(textField, url);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // single-click the link menu to show the menu
      await tester.tapButton(find.text(link, findRichText: true));
      expect(find.text('Open link', findRichText: true), findsOneWidget);
      expect(find.text('Copy link', findRichText: true), findsOneWidget);
      expect(find.text('Remove link', findRichText: true), findsOneWidget);

      // double-click the link menu to open the link
      mock
        ..setLaunchExpectations(
          url: url,
          useSafariVC: false,
          useWebView: false,
          universalLinksOnly: false,
          enableJavaScript: true,
          enableDomStorage: true,
          headers: <String, String>{},
          webOnlyWindowName: null,
          launchMode: PreferredLaunchMode.platformDefault,
        )
        ..setResponse(true);

      await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
      await tester.doubleTapAt(
        tester.getTopLeft(find.text(link, findRichText: true)).translate(5, 5),
      );
      expect(mock.canLaunchCalled, isTrue);
      expect(mock.launchCalled, isTrue);
    });
  });
}
