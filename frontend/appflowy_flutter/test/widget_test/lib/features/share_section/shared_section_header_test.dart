import 'package:appflowy/features/shared_section/presentation/widgets/shared_section_header.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  group('shared_section_header.dart: ', () {
    testWidgets('shows header title', (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: const SharedSectionHeader(),
        ),
      );
      expect(find.text(LocaleKeys.shareSection_shared.tr()), findsOneWidget);
      expect(find.byType(SharedSectionHeader), findsOneWidget);
    });
  });
}
