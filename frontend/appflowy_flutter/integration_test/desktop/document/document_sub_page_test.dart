import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Test cases for the Document SubPageBlock that needs to be covered:
// - [ ] Insert a new SubPageBlock from Slash menu items (Expect it will create a child view under current view)
// - [ ] Delete a SubPageBlock from Block Action Menu (Expect the view is moved to trash / deleted)
// - [ ] Delete a SubPageBlock with backspace when selected (Expect the view is moved to trash / deleted)
// - [ ] Copy+paste a SubPageBlock in same Document (Expect a new view is created under current view with same content and name)
// - [ ] Copy+paste a SubPageBlock in different Document (Expect a new view is created under current view with same content and name)
// - [ ] Cut+paste a SubPageBlock in same Document (Expect the view to be deleted on Cut, and brought back on Paste)
// - [ ] Cut+paste a SubPageBlock in different Document (Expect the view to be deleted on Cut, and brought back on Paste)
// - [ ] Undo delete of a SubPageBlock (Expect the view to be brought back to original position)
// - [ ] Redo delete of a SubPageBlock (Expect the view to be moved to trash again)
// - [ ] Renaming a child view (Expect the view name to be updated in the document)
// - [ ] Deleting a view (in trash) linked to a SubPageBlock deletes the SubPageBlock (Expect the SubPageBlock to be deleted)
// - [ ] Deleting a view (to trash) linked to a SubPageBlock shows a hint that the view is in trash (Expect a hint to be shown)
//
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Document SubPageBlock tests', () {
    testWidgets(
      'Insert a new SubPageBlock from Slash menu items',
      (tester) async {
        // Test code goes here.
      },
    );

    testWidgets('Delete a SubPageBlock from Block Action Menu',
        (WidgetTester tester) async {
      // Test code goes here.
    });

    testWidgets('Delete a SubPageBlock with backspace when selected',
        (WidgetTester tester) async {
      // Test code goes here.
    });

    testWidgets('Copy+paste a SubPageBlock in same Document',
        (WidgetTester tester) async {
      // Test code goes here.
    });

    testWidgets('Copy+paste a SubPageBlock in different Document',
        (WidgetTester tester) async {
      // Test code goes here.
    });

    testWidgets('Cut+paste a SubPageBlock in same Document',
        (WidgetTester tester) async {
      // Test code goes here.
    });

    testWidgets('Cut+paste a SubPageBlock in different Document',
        (WidgetTester tester) async {
      // Test code goes here.
    });

    testWidgets('Undo delete of a SubPageBlock', (WidgetTester tester) async {
      // Test code goes here.
    });

    testWidgets('Redo delete of a SubPageBlock', (WidgetTester tester) async {
      // Test code goes here.
    });

    testWidgets('Renaming a child view', (WidgetTester tester) async {
      // Test code goes here.
    });

    testWidgets('Deleting a view (in trash)', (WidgetTester tester) async {
      // Test code goes here.
    });

    testWidgets('Deleting a view (to trash)', (WidgetTester tester) async {
      // Test code goes here.
    });
  });
}
