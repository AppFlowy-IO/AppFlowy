import 'package:appflowy/features/share_tab/data/models/share_access_level.dart';
import 'package:appflowy/features/shared_section/models/shared_page.dart';
import 'package:appflowy/features/shared_section/presentation/widgets/shared_pages_list.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  group('shared_pages_list.dart: ', () {
    testWidgets('shows list of shared pages', (WidgetTester tester) async {
      final sharedPages = [
        SharedPage(
          view: ViewPB()
            ..id = '1'
            ..name = 'Page 1',
          accessLevel: ShareAccessLevel.readOnly,
        ),
        SharedPage(
          view: ViewPB()
            ..id = '2'
            ..name = 'Page 2',
          accessLevel: ShareAccessLevel.readOnly,
        ),
      ];
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: SharedPagesList(sharedPages: sharedPages),
        ),
      );
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);
      expect(find.byType(SharedPagesList), findsOneWidget);
    });
  });
}
