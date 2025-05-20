import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/people_with_access_section.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  group('people_with_access_section.dart: ', () {
    testWidgets('shows section title and user widgets, triggers callbacks',
        (WidgetTester tester) async {
      final user = SharedUser(
        name: 'Test User',
        email: 'test@user.com',
        accessLevel: ShareAccessLevel.readOnly,
        role: ShareRole.member,
      );

      await tester.pumpWidget(
        WidgetTestWrapper(
          child: PeopleWithAccessSection(
            currentUserEmail: user.email,
            users: [user],
            callbacks: PeopleWithAccessSectionCallbacks(
              onRemoveAccess: (_) {},
              onTurnIntoMember: (_) {},
              onSelectAccessLevel: (_, level) {},
            ),
          ),
        ),
      );
      expect(find.text('People with access'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
    });
  });
}
