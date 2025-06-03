import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/access_level_list_widget.dart';
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
            isInPublicPage: true,
            user: user,
            currentUser: user.copyWith(accessLevel: ShareAccessLevel.readOnly),
          ),
        ),
      );
      // Tap the ghost button to open the menu
      await tester.tap(find.byType(AFGhostButton));
      await tester.pumpAndSettle();
      // Only remove access should be visible
      expect(find.text(LocaleKeys.shareTab_removeAccess.tr()), findsOneWidget);
      expect(find.text(ShareAccessLevel.readOnly.title), findsNothing);
      expect(find.text(ShareAccessLevel.readAndWrite.title), findsNothing);
      expect(find.text(ShareAccessLevel.fullAccess.title), findsNothing);
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
            isInPublicPage: true,
            user: user,
            currentUser:
                user.copyWith(accessLevel: ShareAccessLevel.readAndWrite),
          ),
        ),
      );
      // Tap the ghost button to open the menu
      await tester.tap(find.byType(AFGhostButton));
      await tester.pumpAndSettle();
      // Only remove access should be visible
      expect(find.text(LocaleKeys.shareTab_removeAccess.tr()), findsOneWidget);
      expect(find.text(ShareAccessLevel.readOnly.title), findsNothing);
      expect(find.text(ShareAccessLevel.readAndWrite.title), findsNothing);
      expect(find.text(ShareAccessLevel.fullAccess.title), findsNothing);
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
            isInPublicPage: true,
            user: user,
            currentUser: currentUser,
          ),
        ),
      );
      // Tap the ghost button to open the menu
      await tester.tap(find.byType(AFGhostButton));
      await tester.pumpAndSettle();
      // Permission change options should be visible
      expect(find.text(ShareAccessLevel.fullAccess.title), findsOneWidget);
      expect(find.text(ShareAccessLevel.readOnly.title), findsOneWidget);
      expect(find.text(ShareAccessLevel.readAndWrite.title), findsOneWidget);
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
      await tester.tap(
        find.descendant(
          of: find.byType(TurnIntoMemberWidget),
          matching: find.byType(AFGhostButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(turnedIntoMember, isTrue);
    });
  });
}
