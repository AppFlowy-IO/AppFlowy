import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/setting/settings_popup_menu.dart';
import 'package:appflowy/workspace/presentation/home/hotkeys.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/widgets/font_size_stepper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('test for change scale factor', (tester) async {
    await tester.launchInAnonymousMode();

    /// tap [Setting] button
    await tester.tapButton(find.byType(HomePageSettingsPopupMenu));
    await tester
        .tapButton(find.text(LocaleKeys.settings_popupMenuItem_settings.tr()));

    /// tap [Font Scale Factor]
    await tester.tapButton(
      find.text(LocaleKeys.settings_appearance_fontScaleFactor.tr()),
    );

    /// drag slider
    final slider = find.descendant(
      of: find.byType(FontSizeStepper),
      matching: find.byType(Slider),
    );
    await tester.slideToValue(slider, 0.8);
    expect(appflowyScaleFactor, 0.8);

    await tester.slideToValue(slider, 0.9);
    expect(appflowyScaleFactor, 0.9);

    await tester.slideToValue(slider, 1.0);
    expect(appflowyScaleFactor, 1.0);

    await tester.slideToValue(slider, 1.1);
    expect(appflowyScaleFactor, 1.1);

    await tester.slideToValue(slider, 1.2);
    expect(appflowyScaleFactor, 1.2);
  });
}
