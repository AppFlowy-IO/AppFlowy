import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/access_level_list_widget.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/edit_access_level_widget.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/shared_user_widget.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/turn_into_member_widget.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  group('shared_user_widget.dart: ', () {
    testWidgets('shows user name, email, and role',
        (WidgetTester tester) async {
      final user = SharedUser(
        name: 'Test User',
        email: 'test@user.com',
        accessLevel: ShareAccessLevel.readOnly,
        role: ShareRole.member,
      );
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: SharedUserWidget(
            isInPublicPage: true,
            user: user,
            currentUser: user,
          ),
        ),
      );
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@user.com'), findsOneWidget);
      expect(find.text(LocaleKeys.shareTab_you.tr()), findsOneWidget);
    });

    testWidgets('shows Guest label for guest user',
        (WidgetTester tester) async {
      final user = SharedUser(
        name: 'Guest User',
        email: 'guest@user.com',
        accessLevel: ShareAccessLevel.readOnly,
        role: ShareRole.guest,
      );
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: IntrinsicWidth(
            child: SharedUserWidget(
              isInPublicPage: true,
              user: user,
              currentUser: user,
            ),
          ),
        ),
      );
      expect(find.text(LocaleKeys.shareTab_guest.tr()), findsOneWidget);
    });

    testWidgets('readonly user can only see remove self action in menu',
        (WidgetTester tester) async {
      final user = SharedUser(
        name: 'Readonly User',
        email: 'readonly@user.com',
        accessLevel: ShareAccessLevel.readOnly,
        role: ShareRole.member,
      );
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: SharedUserWidget(
            isInPublicPage: false,
            user: user,
            currentUser: user.copyWith(accessLevel: ShareAccessLevel.readOnly),
          ),
        ),
      );
      // Tap the EditAccessLevelWidget to open the menu
      await tester.tap(find.byType(EditAccessLevelWidget));
      await tester.pumpAndSettle();
      // Only remove access should be visible as an actionable item
      expect(find.text(LocaleKeys.shareTab_removeAccess.tr()), findsOneWidget);
    });

    testWidgets('edit user can only see remove self action in menu',
        (WidgetTester tester) async {
      final user = SharedUser(
        name: 'Edit User',
        email: 'edit@user.com',
        accessLevel: ShareAccessLevel.readAndWrite,
        role: ShareRole.member,
      );
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: SharedUserWidget(
            isInPublicPage: false,
            user: user,
            currentUser: user.copyWith(
              accessLevel: ShareAccessLevel.readAndWrite,
            ),
          ),
        ),
      );
      // Tap the EditAccessLevelWidget to open the menu
      await tester.tap(find.byType(EditAccessLevelWidget));
      await tester.pumpAndSettle();
      // Only remove access should be visible as an actionable item
      expect(find.text(LocaleKeys.shareTab_removeAccess.tr()), findsOneWidget);
    });

    testWidgets('full access user can change another people permission',
        (WidgetTester tester) async {
      final user = SharedUser(
        name: 'Other User',
        email: 'other@user.com',
        accessLevel: ShareAccessLevel.readOnly,
        role: ShareRole.member,
      );
      final currentUser = SharedUser(
        name: 'Full Access User',
        email: 'full@user.com',
        accessLevel: ShareAccessLevel.fullAccess,
        role: ShareRole.member,
      );
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: SharedUserWidget(
            isInPublicPage: false,
            user: user,
            currentUser: currentUser,
          ),
        ),
      );
      // Tap the EditAccessLevelWidget to open the menu
      await tester.tap(find.byType(EditAccessLevelWidget));
      await tester.pumpAndSettle();
      // Permission change options should be visible
      expect(find.text(ShareAccessLevel.readOnly.title), findsWidgets);
      expect(find.text(ShareAccessLevel.readAndWrite.title), findsWidgets);
      expect(find.text(LocaleKeys.shareTab_removeAccess.tr()), findsOneWidget);
    });

    testWidgets('full access user can turn a guest into member',
        (WidgetTester tester) async {
      bool turnedIntoMember = false;
      final guestUser = SharedUser(
        name: 'Guest User',
        email: 'guest@user.com',
        accessLevel: ShareAccessLevel.readOnly,
        role: ShareRole.guest,
      );
      final currentUser = SharedUser(
        name: 'Full Access User',
        email: 'full@user.com',
        accessLevel: ShareAccessLevel.fullAccess,
        role: ShareRole.member,
      );
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: SharedUserWidget(
            isInPublicPage: true,
            user: guestUser,
            currentUser: currentUser,
            callbacks: AccessLevelListCallbacks(
              onSelectAccessLevel: (_) {},
              onTurnIntoMember: () {
                turnedIntoMember = true;
              },
              onRemoveAccess: () {},
            ),
          ),
        ),
      );
      // The TurnIntoMemberWidget should be present
      expect(find.byType(TurnIntoMemberWidget), findsOneWidget);
      // Tap the button (AFGhostButton inside TurnIntoMemberWidget)
      await tester.tap(find.byType(TurnIntoMemberWidget));
      await tester.pumpAndSettle();
      expect(turnedIntoMember, isTrue);
    });

    // Additional tests for more coverage
    testWidgets('public page: member/owner always gets disabled button',
        (WidgetTester tester) async {
      final user = SharedUser(
        name: 'Member User',
        email: 'member@user.com',
        accessLevel: ShareAccessLevel.readAndWrite,
        role: ShareRole.member,
      );
      final currentUser =
          user.copyWith(accessLevel: ShareAccessLevel.fullAccess);
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: SharedUserWidget(
            isInPublicPage: true,
            user: user,
            currentUser: currentUser,
          ),
        ),
      );
      expect(find.byType(AFGhostTextButton), findsOneWidget);
      expect(find.byType(EditAccessLevelWidget), findsNothing);
    });

    testWidgets('private page: full access user can manage others',
        (WidgetTester tester) async {
      final user = SharedUser(
        name: 'Other User',
        email: 'other@user.com',
        accessLevel: ShareAccessLevel.readOnly,
        role: ShareRole.member,
      );
      final currentUser = SharedUser(
        name: 'Full Access User',
        email: 'full@user.com',
        accessLevel: ShareAccessLevel.fullAccess,
        role: ShareRole.member,
      );
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: SharedUserWidget(
            isInPublicPage: false,
            user: user,
            currentUser: currentUser,
          ),
        ),
      );
      expect(find.byType(EditAccessLevelWidget), findsOneWidget);
    });

    testWidgets('private page: readonly user sees disabled button for others',
        (WidgetTester tester) async {
      final user = SharedUser(
        name: 'Other User',
        email: 'other@user.com',
        accessLevel: ShareAccessLevel.readOnly,
        role: ShareRole.member,
      );
      final currentUser = SharedUser(
        name: 'Readonly User',
        email: 'readonly@user.com',
        accessLevel: ShareAccessLevel.readOnly,
        role: ShareRole.member,
      );
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: SharedUserWidget(
            isInPublicPage: false,
            user: user,
            currentUser: currentUser,
          ),
        ),
      );
      expect(find.byType(AFGhostTextButton), findsOneWidget);
      expect(find.byType(EditAccessLevelWidget), findsNothing);
    });

    testWidgets('self: full access user cannot change own access',
        (WidgetTester tester) async {
      final user = SharedUser(
        name: 'Full Access User',
        email: 'full@user.com',
        accessLevel: ShareAccessLevel.fullAccess,
        role: ShareRole.member,
      );
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: SharedUserWidget(
            isInPublicPage: false,
            user: user,
            currentUser: user,
          ),
        ),
      );
      expect(find.byType(AFGhostTextButton), findsOneWidget);
      expect(find.byType(EditAccessLevelWidget), findsNothing);
    });

    testWidgets('self: readonly user can only remove self',
        (WidgetTester tester) async {
      final user = SharedUser(
        name: 'Readonly User',
        email: 'readonly@user.com',
        accessLevel: ShareAccessLevel.readOnly,
        role: ShareRole.member,
      );
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: SharedUserWidget(
            isInPublicPage: false,
            user: user,
            currentUser: user,
          ),
        ),
      );
      expect(find.byType(EditAccessLevelWidget), findsOneWidget);
      // Open the menu and check only remove access is present
      await tester.tap(find.byType(EditAccessLevelWidget));
      await tester.pumpAndSettle();
      expect(find.text(LocaleKeys.shareTab_removeAccess.tr()), findsOneWidget);
    });
  });
}
