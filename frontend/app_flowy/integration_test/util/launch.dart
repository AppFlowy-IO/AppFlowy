import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base.dart';

extension AppFlowyLaunch on WidgetTester {
  Future<void> tapGoButton() async {
    await tapButtonWithName(LocaleKeys.letsGoButtonText.tr());
    return;
  }

  Future<void> tapCreateButton() async {
    await tapButtonWithName(LocaleKeys.settings_files_create.tr());
    return;
  }

  Future<void> expectToSeeWelcomePage() async {
    expect(find.byType(HomeStack), findsOneWidget);
    expect(find.textContaining('Read me'), findsNWidgets(2));
  }
}
