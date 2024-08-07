import 'dart:io';

import 'package:flutter/services.dart';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_upload_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/mock/mock_file_picker.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('file block in document', () {
    testWidgets('insert a file from local file + rename file', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent(name: 'Insert file test');

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.showSlashMenu();
      await tester.editor.tapSlashMenuItemWithName('File');
      expect(find.byType(FileBlockComponent), findsOneWidget);

      await tester.tap(find.byType(FileBlockComponent));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(FileUploadMenu), findsOneWidget);

      final image = await rootBundle.load('assets/test/images/sample.jpeg');
      final tempDirectory = await getTemporaryDirectory();
      final filePath = p.join(tempDirectory.path, 'sample.jpeg');
      final file = File(filePath)..writeAsBytesSync(image.buffer.asUint8List());

      mockPickFilePaths(paths: [filePath]);

      await getIt<KeyValueStorage>().set(KVKeys.kCloudType, '0');
      await tester.tap(
        find.text(LocaleKeys.document_plugins_file_fileUploadHint.tr()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FileUploadMenu), findsNothing);
      expect(find.byType(FileBlockComponent), findsOneWidget);

      final node = tester.editor.getCurrentEditorState().getNodeAtPath([0])!;
      expect(node.type, FileBlockKeys.type);
      expect(node.attributes[FileBlockKeys.url], isNotEmpty);
      expect(
        node.attributes[FileBlockKeys.urlType],
        FileUrlType.local.toIntValue(),
      );

      // Check the name of the file is correctly extracted
      expect(node.attributes[FileBlockKeys.name], 'sample.jpeg');
      expect(find.text('sample.jpeg'), findsOneWidget);

      const newName = "Renamed file";

      // Hover on the widget to see the three dots to open FileBlockMenu
      await tester.hoverOnWidget(
        find.byType(FileBlockComponent),
        onHover: () async {
          await tester.tap(find.byType(FileMenuTrigger));
          await tester.pumpAndSettle();

          await tester.tap(
            find.text(LocaleKeys.document_plugins_file_renameFile_title.tr()),
          );
        },
      );
      await tester.pumpAndSettle();

      expect(find.byType(FlowyTextField), findsOneWidget);
      await tester.enterText(find.byType(FlowyTextField), newName);
      await tester.pump();

      await tester.tap(find.text(LocaleKeys.button_save.tr()));
      await tester.pumpAndSettle();

      final updatedNode =
          tester.editor.getCurrentEditorState().getNodeAtPath([0])!;
      expect(updatedNode.attributes[FileBlockKeys.name], newName);
      expect(find.text(newName), findsOneWidget);

      // remove the temp file
      file.deleteSync();
    });

    testWidgets('insert a file from network', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent(name: 'Insert file test');

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.showSlashMenu();
      await tester.editor.tapSlashMenuItemWithName('File');
      expect(find.byType(FileBlockComponent), findsOneWidget);

      await tester.tap(find.byType(FileBlockComponent));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(FileUploadMenu), findsOneWidget);

      // Navigate to integrate link tab
      await tester.tapButtonWithName(
        LocaleKeys.document_plugins_file_networkTab.tr(),
      );
      await tester.pumpAndSettle();

      const url =
          'https://images.unsplash.com/photo-1469474968028-56623f02e42e?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&dl=david-marcu-78A265wPiO4-unsplash.jpg&w=640';
      await tester.enterText(
        find.descendant(
          of: find.byType(FileUploadMenu),
          matching: find.byType(FlowyTextField),
        ),
        url,
      );
      await tester.tapButton(
        find.descendant(
          of: find.byType(FileUploadMenu),
          matching: find.text(
            LocaleKeys.document_plugins_file_networkAction.tr(),
            findRichText: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FileUploadMenu), findsNothing);
      expect(find.byType(FileBlockComponent), findsOneWidget);

      final node = tester.editor.getCurrentEditorState().getNodeAtPath([0])!;
      expect(node.type, FileBlockKeys.type);
      expect(node.attributes[FileBlockKeys.url], isNotEmpty);
      expect(
        node.attributes[FileBlockKeys.urlType],
        FileUrlType.network.toIntValue(),
      );

      // Check the name is correctly extracted from the url
      expect(
        node.attributes[FileBlockKeys.name],
        'photo-1469474968028-56623f02e42e',
      );
      expect(find.text('photo-1469474968028-56623f02e42e'), findsOneWidget);
    });
  });
}
