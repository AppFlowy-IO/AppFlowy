import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/shared_user_widget.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
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
              user: user,
              currentUser: user,
            ),
          ),
        ),
      );
      expect(find.text(LocaleKeys.shareTab_guest.tr()), findsOneWidget);
    });
  });
}
