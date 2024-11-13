import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/base/view_page/app_bar_buttons.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/document_immersive_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document page style:', () {
    double getCurrentEditorFontSize() {
      final editorPage = find
          .byType(AppFlowyEditorPage)
          .evaluate()
          .single
          .widget as AppFlowyEditorPage;
      return editorPage.styleCustomizer
          .style()
          .textStyleConfiguration
          .text
          .fontSize!;
    }

    double getCurrentEditorLineHeight() {
      final editorPage = find
          .byType(AppFlowyEditorPage)
          .evaluate()
          .single
          .widget as AppFlowyEditorPage;
      return editorPage.styleCustomizer
          .style()
          .textStyleConfiguration
          .lineHeight;
    }

    testWidgets('change font size in page style settings', (tester) async {
      await tester.launchInAnonymousMode();

      // click the getting start page
      await tester.openPage(gettingStarted);
      // click the layout button
      await tester.tapButton(find.byType(MobileViewPageLayoutButton));
      expect(getCurrentEditorFontSize(), PageStyleFontLayout.normal.fontSize);
      // change font size from normal to large
      await tester.tapSvgButton(FlowySvgs.m_font_size_large_s);
      expect(getCurrentEditorFontSize(), PageStyleFontLayout.large.fontSize);
      // change font size from large to small
      await tester.tapSvgButton(FlowySvgs.m_font_size_small_s);
      expect(getCurrentEditorFontSize(), PageStyleFontLayout.small.fontSize);
    });

    testWidgets('change line height in page style settings', (tester) async {
      await tester.launchInAnonymousMode();

      // click the getting start page
      await tester.openPage(gettingStarted);
      // click the layout button
      await tester.tapButton(find.byType(MobileViewPageLayoutButton));
      var lineHeight = getCurrentEditorLineHeight();
      expect(
        lineHeight,
        PageStyleLineHeightLayout.normal.lineHeight,
      );
      // change line height from normal to large
      await tester.tapSvgButton(FlowySvgs.m_layout_large_s);
      await tester.pumpAndSettle();
      lineHeight = getCurrentEditorLineHeight();
      expect(
        lineHeight,
        PageStyleLineHeightLayout.large.lineHeight,
      );
      // change line height from large to small
      await tester.tapSvgButton(FlowySvgs.m_layout_small_s);
      lineHeight = getCurrentEditorLineHeight();
      expect(
        lineHeight,
        PageStyleLineHeightLayout.small.lineHeight,
      );
    });

    testWidgets('use built-in image as cover', (tester) async {
      await tester.launchInAnonymousMode();

      // click the getting start page
      await tester.openPage(gettingStarted);
      // click the layout button
      await tester.tapButton(find.byType(MobileViewPageLayoutButton));
      // toggle the preset button
      await tester.tapSvgButton(FlowySvgs.m_page_style_presets_m);

      // select the first preset
      final firstBuiltInImage = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                PageStyleCoverImageType.builtInImagePath('1'),
      );
      await tester.tap(firstBuiltInImage);

      // click done button to exit the page style settings
      await tester.tapButton(find.byType(BottomSheetDoneButton).first);

      // check the cover
      final builtInCover = find.descendant(
        of: find.byType(DocumentImmersiveCover),
        matching: firstBuiltInImage,
      );
      expect(builtInCover, findsOneWidget);
    });
  });
}
