import 'package:appflowy/ai/widgets/prompt_input/desktop_prompt_input.dart';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_ask_ai_entrance.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/util.dart';

void main() {
  setUpAll(() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('Test for searching', (tester) async {
    await tester.initializeAppFlowy(
      cloudType: AuthenticatorType.appflowyCloudSelfHost,
    );
    await tester.tapGoogleLoginInButton();
    await tester.expectToSeeHomePageWithGetStartedPage();

    /// show searching page
    final searchingButton = find.text(LocaleKeys.search_label.tr());
    await tester.tapButton(searchingButton);
    final askAIButton = find.byType(SearchAskAiEntrance);
    expect(askAIButton, findsOneWidget);

    /// searching for [gettingStarted]
    final searchField = find.byType(SearchField);
    final textFiled =
        find.descendant(of: searchField, matching: find.byType(TextField));
    await tester.enterText(textFiled, gettingStarted);
    await tester.pumpAndSettle(Duration(seconds: 1));

    /// tap ask AI button
    await tester.tapButton(askAIButton);
    expect(find.byType(DesktopPromptInput), findsOneWidget);
  });
}
