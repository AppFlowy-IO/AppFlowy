// import 'dart:io';

// import 'package:appflowy/generated/locale_keys.g.dart';
// import 'package:appflowy_editor/appflowy_editor.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:integration_test/integration_test.dart';

// import 'shared/mock/mock_file_picker.dart';
// import 'shared/util.dart';
// import 'package:path/path.dart' as p;

// void main() {
//   IntegrationTestWidgetsFlutterBinding.ensureInitialized();
//   group('import file from notion', () {
//     testWidgets('import markdown zip from notion', (tester) async {
//       const mainPageName = 'AppFlowy Test';
//       const subPageOneName = 'Appflowy Subpage 1';
//       const subPageTwoName = 'AppFlowy Subpage 2';
//       const subSubPageName = 'AppFlowy SubSub Page';
//       final context = await tester.initializeAppFlowy();
//       await tester.tapGoButton();

//       // expect to see a readme page
//       tester.expectToSeePageName(gettingStarted);

//       await tester.tapAddViewButton();
//       await tester.tapImportButton();

//       final paths = [
//         p.join(
//           context.applicationDataDirectory,
//           'import_page_from_notion_test.zip',
//         )
//       ];
//       final ByteData data = await rootBundle
//           .load('assets/test/workspaces/import_page_from_notion_test.zip');
//       final file = File(paths[0]);
//       await file.writeAsBytes(
//         data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
//       );

//       await tester.tapButtonWithName(
//         LocaleKeys.importPanel_importFromNotionMarkdownZip.tr(),
//       );
//       expect(
//         find.widgetWithText(
//           Card,
//           LocaleKeys.importPanel_fromMarkdownZip.tr(),
//         ),
//         findsOneWidget,
//       );
//       await tester
//           .tapButtonWithName(LocaleKeys.importPanel_fromMarkdownZip.tr());
//       expect(
//         find.text(LocaleKeys.importPanel_importFromNotionMarkdownZip.tr()),
//         findsOneWidget,
//       );
//       mockPickFilePaths(
//         paths: paths,
//       );
//       await tester.tapButtonWithName(LocaleKeys.importPanel_uploadZipFile.tr());
//       tester.expectToSeePageName(mainPageName);
//       await tester.openPage(mainPageName);
//       //test if the main page is imported correctly
//       final mainPageEditorState = tester.editor.getCurrentEditorState();
//       expect(
//         mainPageEditorState.getNodeAtPath([0])!.type,
//         HeadingBlockKeys.type,
//       );
//       expect(
//         mainPageEditorState.getNodeAtPath([2])!.type,
//         ImageBlockKeys.type,
//       );
//       expect(
//         mainPageEditorState.getNodeAtPath([3])!.type,
//         ImageBlockKeys.type,
//       );
//       expect(
//         mainPageEditorState.getNodeAtPath([4])!.type,
//         DividerBlockKeys.type,
//       );
//       expect(
//         mainPageEditorState.getNodeAtPath([5])!.type,
//         BulletedListBlockKeys.type,
//       );
//       expect(
//         mainPageEditorState.getNodeAtPath([8])!.type,
//         NumberedListBlockKeys.type,
//       );
//       expect(
//         mainPageEditorState.getNodeAtPath([9])!.type,
//         NumberedListBlockKeys.type,
//       );
//       expect(
//         mainPageEditorState
//             .getNodeAtPath([10])!
//             .attributes
//             .values
//             .elementAt(0)[0]['attributes']['mention']['type'],
//         'page',
//       );
//       expect(
//         mainPageEditorState
//             .getNodeAtPath([11])!
//             .attributes
//             .values
//             .elementAt(0)[0]['attributes']['mention']['type'],
//         'page',
//       );
//       expect(
//         mainPageEditorState
//             .getNodeAtPath([12])!
//             .attributes
//             .values
//             .elementAt(0)[0]['attributes']['mention']['type'],
//         'page',
//       );
//       //the below line get the href from the text
//       final hrefFromText = mainPageEditorState
//           .getNodeAtPath([13])!
//           .attributes
//           .values
//           .elementAt(0)[0]['attributes']['href'];
//       expect(
//         hrefFromText,
//         'https://appflowy.gitbook.io/docs/essential-documentation/readme',
//       );

//       //test if all subpages are imported
//       await tester.openPage(mainPageName);
//       tester.expectToSeePageName(subPageOneName);
//       tester.expectToSeePageName(subPageTwoName);

//       // await tester.expandPage(subPageTwoName);
//       // tester.expectToSeePageName(subSubPageName);

//       //test if subpage 1 is imported correctly
//       await tester.openPage(subPageOneName);
//       final subPageOneEditorState = tester.editor.getCurrentEditorState();
//       expect(
//         subPageOneEditorState.getNodeAtPath([0])!.type,
//         HeadingBlockKeys.type,
//       );
//       expect(
//         subPageOneEditorState.getNodeAtPath([1])!.type,
//         HeadingBlockKeys.type,
//       );
//       expect(
//         subPageOneEditorState.getNodeAtPath([2])!.type,
//         ImageBlockKeys.type,
//       );
//       //test if subpage 2 is imported correctly
//       await tester.openPage(subPageTwoName);
//       final subPageTwoEditorState = tester.editor.getCurrentEditorState();
//       expect(
//         subPageTwoEditorState.getNodeAtPath([0])!.type,
//         HeadingBlockKeys.type,
//       );
//       expect(
//         subPageTwoEditorState.getNodeAtPath([1])!.type,
//         ImageBlockKeys.type,
//       );
//       expect(
//         subPageTwoEditorState.getNodeAtPath([2])!.type,
//         ImageBlockKeys.type,
//       );
//       expect(
//         subPageTwoEditorState
//             .getNodeAtPath([3])!
//             .attributes
//             .values
//             .elementAt(0)[0]['attributes']['mention']['type'],
//         'page',
//       );
//       //test if subSubPage is imported correctly
//       await tester.openPage(subSubPageName);
//       final subSubPageEditorState = tester.editor.getCurrentEditorState();
//       expect(
//         subSubPageEditorState.getNodeAtPath([0])!.type,
//         HeadingBlockKeys.type,
//       );
//       expect(
//         subSubPageEditorState.getNodeAtPath([0])!.type,
//         HeadingBlockKeys.type,
//       );
//       expect(
//         subSubPageEditorState.getNodeAtPath([2])!.type,
//         ImageBlockKeys.type,
//       );
//     });
//   });
// }
