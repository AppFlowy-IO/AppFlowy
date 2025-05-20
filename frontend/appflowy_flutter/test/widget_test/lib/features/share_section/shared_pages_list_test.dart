import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/features/share_tab/data/models/share_access_level.dart';
import 'package:appflowy/features/shared_section/models/shared_page.dart';
import 'package:appflowy/features/shared_section/presentation/widgets/shared_pages_list.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
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
          child: SingleChildScrollView(
            child: SharedPagesList(sharedPages: sharedPages),
          ),
        ),
      );
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);
      expect(find.byType(SharedPagesList), findsOneWidget);
    });
  });
}

class MockKeyValueStorage extends Mock implements KeyValueStorage {}
