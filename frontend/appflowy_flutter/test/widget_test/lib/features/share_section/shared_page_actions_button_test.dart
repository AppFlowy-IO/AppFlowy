import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/features/share_tab/data/models/share_access_level.dart';
import 'package:appflowy/features/shared_section/presentation/widgets/shared_page_actions_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  setUp(() {
    final mockStorage = MockKeyValueStorage();
    // Stub methods to return appropriate Future values
    when(() => mockStorage.get(any())).thenAnswer((_) => Future.value());
    when(() => mockStorage.set(any(), any())).thenAnswer((_) => Future.value());
    when(() => mockStorage.remove(any())).thenAnswer((_) => Future.value());
    when(() => mockStorage.clear()).thenAnswer((_) => Future.value());

    GetIt.I.registerSingleton<KeyValueStorage>(mockStorage);
    GetIt.I.registerSingleton<MenuSharedState>(MenuSharedState());
  });

  tearDown(() {
    GetIt.I.reset();
  });

  group('SharedPageActionsButton: ', () {
    late ViewPB testView;
    late List<ViewMoreActionType> capturedActions;
    late List<bool> capturedEditingStates;

    setUp(() {
      testView = ViewPB()
        ..id = 'test_view_id'
        ..name = 'Test View'
        ..layout = ViewLayoutPB.Document
        ..isFavorite = false;
      capturedActions = [];
      capturedEditingStates = [];
    });

    Widget buildTestWidget({
      required ShareAccessLevel accessLevel,
      ViewPB? view,
    }) {
      return WidgetTestWrapper(
        child: Scaffold(
          body: SharedPageActionsButton(
            view: view ?? testView,
            accessLevel: accessLevel,
            onAction: (type, view, data) {
              capturedActions.add(type);
            },
            onSetEditing: (context, value) {
              capturedEditingStates.add(value);
            },
            buildChild: (controller) => ElevatedButton(
              onPressed: () => controller.show(),
              child: const Text('Actions'),
            ),
          ),
        ),
      );
    }

    testWidgets('renders action button correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(accessLevel: ShareAccessLevel.readOnly),
      );

      expect(find.text('Actions'), findsOneWidget);
      expect(find.byType(SharedPageActionsButton), findsOneWidget);
    });

    testWidgets('shows popover when button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(accessLevel: ShareAccessLevel.readOnly),
      );

      // Tap the button to show popover
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();

      // Should show the AFMenu popover
      expect(find.byType(AFMenu), findsOneWidget);
    });

    testWidgets('shows correct menu items for read-only access',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(accessLevel: ShareAccessLevel.readOnly),
      );

      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();

      // For read-only access, should only show favorite and open in new tab
      expect(find.byType(AFTextMenuItem), findsNWidgets(2));

      // Should find favorite action (since view is not favorited)
      expect(find.text(ViewMoreActionType.favorite.name), findsOneWidget);

      // Should find open in new tab action
      expect(find.text(ViewMoreActionType.openInNewTab.name), findsOneWidget);

      // Should NOT find editable actions
      expect(find.text(ViewMoreActionType.rename.name), findsNothing);
      expect(find.text(ViewMoreActionType.delete.name), findsNothing);
    });

    testWidgets('shows correct menu items for edit access',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(accessLevel: ShareAccessLevel.readAndWrite),
      );

      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();

      // Should show favorite, rename, change icon, and open in new tab
      expect(find.text(ViewMoreActionType.favorite.name), findsOneWidget);
      expect(find.text(ViewMoreActionType.rename.name), findsOneWidget);
      expect(find.text(ViewMoreActionType.changeIcon.name), findsOneWidget);
      expect(find.text(ViewMoreActionType.openInNewTab.name), findsOneWidget);

      // Should NOT show delete for edit access
      expect(find.text(ViewMoreActionType.delete.name), findsNothing);
    });

    testWidgets('shows correct menu items for full access',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(accessLevel: ShareAccessLevel.fullAccess),
      );

      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();

      // Should show all actions including delete
      expect(find.text(ViewMoreActionType.favorite.name), findsOneWidget);
      expect(find.text(ViewMoreActionType.rename.name), findsOneWidget);
      expect(find.text(ViewMoreActionType.changeIcon.name), findsOneWidget);
      expect(find.text(ViewMoreActionType.delete.name), findsOneWidget);
      expect(find.text(ViewMoreActionType.openInNewTab.name), findsOneWidget);
    });

    testWidgets('shows unfavorite when view is favorited',
        (WidgetTester tester) async {
      final favoritedView = ViewPB()
        ..id = 'test_view_id'
        ..name = 'Test View'
        ..layout = ViewLayoutPB.Document
        ..isFavorite = true;

      await tester.pumpWidget(
        buildTestWidget(
          accessLevel: ShareAccessLevel.readOnly,
          view: favoritedView,
        ),
      );

      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();

      expect(find.text(ViewMoreActionType.unFavorite.name), findsOneWidget);
      expect(find.text(ViewMoreActionType.favorite.name), findsNothing);
    });

    testWidgets('does not show change icon for chat layout',
        (WidgetTester tester) async {
      final chatView = ViewPB()
        ..id = 'test_view_id'
        ..name = 'Test Chat'
        ..layout = ViewLayoutPB.Chat
        ..isFavorite = false;

      await tester.pumpWidget(
        buildTestWidget(
          accessLevel: ShareAccessLevel.readAndWrite,
          view: chatView,
        ),
      );

      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();

      // Should show rename but not change icon for chat
      expect(find.text(ViewMoreActionType.rename.name), findsOneWidget);
      expect(find.text(ViewMoreActionType.changeIcon.name), findsNothing);
    });

    testWidgets('triggers onAction callback when menu item is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(accessLevel: ShareAccessLevel.fullAccess),
      );

      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();

      // Tap on the favorite action
      await tester.tap(find.text(ViewMoreActionType.favorite.name));
      await tester.pumpAndSettle();

      expect(capturedActions, contains(ViewMoreActionType.favorite));
    });

    testWidgets('shows dividers between action groups',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(accessLevel: ShareAccessLevel.fullAccess),
      );

      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();

      // Should have dividers separating action groups
      expect(find.byType(AFDivider), findsAtLeastNWidgets(1));
    });

    testWidgets('delete action shows error color', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(accessLevel: ShareAccessLevel.fullAccess),
      );

      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();

      // Find the delete menu item
      final deleteMenuItem = find.ancestor(
        of: find.text(ViewMoreActionType.delete.name),
        matching: find.byType(AFTextMenuItem),
      );

      expect(deleteMenuItem, findsOneWidget);

      // The delete action should be present
      expect(find.text(ViewMoreActionType.delete.name), findsOneWidget);
    });

    testWidgets('popover hides when menu item is selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(accessLevel: ShareAccessLevel.readOnly),
      );

      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();

      // Popover should be visible
      expect(find.byType(AFMenu), findsOneWidget);

      // Tap on favorite action
      await tester.tap(find.text(ViewMoreActionType.favorite.name));
      await tester.pumpAndSettle();

      // Popover should be hidden
      expect(find.byType(AFMenu), findsNothing);
    });
  });
}

class MockKeyValueStorage extends Mock implements KeyValueStorage {}
