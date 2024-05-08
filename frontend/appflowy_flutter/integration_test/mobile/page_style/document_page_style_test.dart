// ignore_for_file: unused_import

import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/base/view_page/app_bar_buttons.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_buttons.dart';
import 'package:appflowy/mobile/presentation/home/home.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/document_immersive_cover.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/document_immersive_cover_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_layout.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../../shared/dir.dart';
import '../../shared/mock/mock_file_picker.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document page style', () {
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
          .text
          .height!;
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
      expect(
        getCurrentEditorLineHeight(),
        PageStyleLineHeightLayout.normal.lineHeight,
      );
      // change line height from normal to large
      await tester.tapSvgButton(FlowySvgs.m_layout_large_s);
      expect(
        getCurrentEditorLineHeight(),
        PageStyleLineHeightLayout.large.lineHeight,
      );
      // change line height from large to small
      await tester.tapSvgButton(FlowySvgs.m_layout_small_s);
      expect(
        getCurrentEditorLineHeight(),
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
