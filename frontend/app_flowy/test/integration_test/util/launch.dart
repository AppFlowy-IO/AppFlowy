import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base.dart';

extension AppFlowyLaunch on WidgetTester {
  Future<void> tapGoButton() async {
    final goButton = find.textContaining(LocaleKeys.letsGoButtonText.tr());
    await tapButton(goButton);
    return;
  }
}
