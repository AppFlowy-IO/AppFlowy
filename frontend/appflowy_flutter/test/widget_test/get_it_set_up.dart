import 'package:appflowy/core/config/kv.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'lib/features/share_section/shared_page_actions_button_test.dart';

void setUpGetIt() {
  final mockStorage = MockKeyValueStorage();
  // Stub methods to return appropriate Future values
  when(() => mockStorage.get(any())).thenAnswer((_) => Future.value());
  when(() => mockStorage.getBool(any())).thenAnswer((_) => Future.value());
  when(() => mockStorage.set(any(), any())).thenAnswer((_) => Future.value());
  when(() => mockStorage.setBool(any(), any()))
      .thenAnswer((_) => Future.value());
  when(() => mockStorage.remove(any())).thenAnswer((_) => Future.value());
  when(() => mockStorage.clear()).thenAnswer((_) => Future.value());

  GetIt.I.registerSingleton<KeyValueStorage>(mockStorage);
}

void tearDownGetIt() {
  GetIt.I.reset();
}
