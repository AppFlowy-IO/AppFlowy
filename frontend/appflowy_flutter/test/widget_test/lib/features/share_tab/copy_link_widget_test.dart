import 'package:appflowy/features/share_tab/data/repositories/local_share_with_user_repository.dart';
import 'package:appflowy/features/share_tab/logic/share_with_user_bloc.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/copy_link_widget.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const ClipboardServiceData());
  });

  setUp(() {
    if (getIt.isRegistered<ClipboardService>()) {
      getIt.unregister<ClipboardService>();
    }
    getIt.registerSingleton<ClipboardService>(_MockClipboardService());
  });

  group('copy_link_widget.dart: ', () {
    testWidgets('shows the share link and copy button, triggers callback',
        (WidgetTester tester) async {
      final mockClipboard = getIt<ClipboardService>() as _MockClipboardService;
      when(() => mockClipboard.setData(any())).thenAnswer((_) async {});
      final bloc = ShareWithUserBloc(
        repository: LocalShareWithUserRepository(),
        pageId: 'pageId',
        workspaceId: 'workspaceId',
      );
      const testLink = 'https://test.link';
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: BlocProvider<ShareWithUserBloc>.value(
            value: bloc,
            child: CopyLinkWidget(shareLink: testLink),
          ),
        ),
      );

      expect(find.text(testLink), findsOneWidget);
      expect(find.text(LocaleKeys.shareTab_copyLink.tr()), findsOneWidget);
      await tester.tap(find.text(LocaleKeys.shareTab_copyLink.tr()));
      await tester.pumpAndSettle();
      // Timer (duration: 0:00:03.000000, periodic: false), created:
      // #0      new FakeTimer._ (package:fake_async/fake_async.dart:308:62)
      await tester.pump(const Duration(seconds: 4));

      verify(() => mockClipboard.setData(any())).called(1);
    });
  });
}

class _MockClipboardService extends Mock implements ClipboardService {}
