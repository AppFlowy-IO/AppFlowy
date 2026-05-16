import 'package:appflowy/features/share_tab/presentation/widgets/share_with_user_widget.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  group('share_with_user_widget.dart: ', () {
    testWidgets('shows input and button, triggers callback on valid email',
        (WidgetTester tester) async {
      List<String>? invited;
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: ShareWithUserWidget(
            onInvite: (emails) => invited = emails,
          ),
        ),
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(LocaleKeys.shareTab_invite.tr()), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'test@user.com');
      await tester.pumpAndSettle();
      await tester.tap(find.text(LocaleKeys.shareTab_invite.tr()));
      await tester.pumpAndSettle();
      expect(invited, isNotNull);
      expect(invited, contains('test@user.com'));
    });
  });
}
