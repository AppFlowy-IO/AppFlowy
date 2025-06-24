import 'package:appflowy/features/share_tab/data/models/shared_group.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/general_access_section.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  group('general_access_section.dart: ', () {
    testWidgets('shows section title and SharedGroupWidget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: GeneralAccessSection(
            group: SharedGroup(
              id: '1',
              name: 'Group 1',
              icon: '👥',
            ),
          ),
        ),
      );
      expect(find.text(LocaleKeys.shareTab_generalAccess.tr()), findsOneWidget);
      expect(find.byType(GeneralAccessSection), findsOneWidget);
    });
  });
}
