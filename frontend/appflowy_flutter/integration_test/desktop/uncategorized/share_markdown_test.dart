import 'dart:io';

import 'package:appflowy/plugins/shared/share/share_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../../shared/mock/mock_file_picker.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('share markdown in document page', () {
    testWidgets('click the share button in document page', (tester) async {
      final context = await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // mock the file picker
      final path = await mockSaveFilePath(
        p.join(context.applicationDataDirectory, 'test.md'),
      );
      // click the share button and select markdown
      await tester.tapShareButton();
      await tester.tapMarkdownButton();

      // expect to see the success dialog
      tester.expectToExportSuccess();

      final file = File(path);
      final isExist = file.existsSync();
      expect(isExist, true);
      final markdown = file.readAsStringSync();
      expect(markdown, expectedMarkdown);
    });

    testWidgets(
      'share the markdown after renaming the document name',
      (tester) async {
        final context = await tester.initializeAppFlowy();
        await tester.tapAnonymousSignInButton();

        // expect to see a getting started page
        tester.expectToSeePageName(gettingStarted);

        // rename the document
        await tester.hoverOnPageName(
          gettingStarted,
          onHover: () async {
            await tester.renamePage('example');
          },
        );

        final shareButton = find.byType(ShareButton);
        final shareButtonState = tester.widget(shareButton) as ShareButton;

        final path = await mockSaveFilePath(
          p.join(
            context.applicationDataDirectory,
            '${shareButtonState.view.name}.md',
          ),
        );

        // click the share button and select markdown
        await tester.tapShareButton();
        await tester.tapMarkdownButton();

        // expect to see the success dialog
        tester.expectToExportSuccess();

        final file = File(path);
        final isExist = file.existsSync();
        expect(isExist, true);
      },
    );
  });
}

const expectedMarkdown = '''
# Welcome to AppFlowy!
## Here are the basics
- [ ] Click anywhere and just start typing.
- [ ] Highlight any text, and use the editing menu to _style_ **your** <u>writing</u> `however` you ~~like.~~
- [ ] As soon as you type `/` a menu will pop up. Select different types of content blocks you can add.
- [ ] Type `/` followed by `/bullet` or `/num` to create a list.
- [x] Click `+ New Page `button at the bottom of your sidebar to add a new page.
- [ ] Click `+` next to any page title in the sidebar to quickly add a new subpage, `Document`, `Grid`, or `Kanban Board`.

---

## Keyboard shortcuts, markdown, and code block
1. Keyboard shortcuts [guide](https://appflowy.gitbook.io/docs/essential-documentation/shortcuts)
1. Markdown [reference](https://appflowy.gitbook.io/docs/essential-documentation/markdown)
1. Type `/code` to insert a code block
```rust
// This is the main function.
fn main() {
    // Print text to the console.
    println!("Hello World!");
}
```

## Have a question❓
> Click `?` at the bottom right for help and support.

> 🥰
> 
> Like AppFlowy? Follow us:
> [GitHub](https://github.com/AppFlowy-IO/AppFlowy)
> [Twitter](https://twitter.com/appflowy): @appflowy
> [Newsletter](https://blog-appflowy.ghost.io/)
> 




''';
