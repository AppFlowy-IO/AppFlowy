import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';

import 'test_asset_bundle.dart';

class WidgetTestApp extends StatelessWidget {
  const WidgetTestApp({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      useFallbackTranslations: true,
      saveLocale: false,
      assetLoader: const TestBundleAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          localizationsDelegates: context.localizationDelegates,
          theme: ThemeData.light().copyWith(
            extensions: const [
              AFThemeExtension(
                warning: Colors.transparent,
                success: Colors.transparent,
                tint1: Colors.transparent,
                tint2: Colors.transparent,
                tint3: Colors.transparent,
                tint4: Colors.transparent,
                tint5: Colors.transparent,
                tint6: Colors.transparent,
                tint7: Colors.transparent,
                tint8: Colors.transparent,
                tint9: Colors.transparent,
                textColor: Colors.transparent,
                secondaryTextColor: Colors.transparent,
                strongText: Colors.transparent,
                greyHover: Colors.transparent,
                greySelect: Colors.transparent,
                lightGreyHover: Colors.transparent,
                toggleOffFill: Colors.transparent,
                progressBarBGColor: Colors.transparent,
                toggleButtonBGColor: Colors.transparent,
                calendarWeekendBGColor: Colors.transparent,
                gridRowCountColor: Colors.transparent,
                code: TextStyle(),
                callout: TextStyle(),
                calloutBGColor: Colors.transparent,
                tableCellBGColor: Colors.transparent,
                caption: TextStyle(),
                onBackground: Colors.transparent,
                background: Colors.transparent,
                borderColor: Colors.transparent,
                scrollbarColor: Colors.transparent,
                scrollbarHoverColor: Colors.transparent,
              ),
            ],
          ),
          home: Scaffold(
            body: child,
          ),
        ),
      ),
    );
  }
}
