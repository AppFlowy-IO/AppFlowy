import 'package:appflowy/features/settings/settings.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;
  late DataLocationBloc bloc;

  const defaultPath = '/default/path';
  const customPath = '/custom/path';

  setUp(() {
    repository = MockSettingsRepository();
    when(() => repository.getUserDataLocation()).thenAnswer(
      (_) async => FlowyResult.success(
        UserDataLocation(path: defaultPath, isCustom: false),
      ),
    );
    bloc = DataLocationBloc(repository: repository)
      ..add(DataLocationEvent.initial());
  });

  tearDown(() async {
    await bloc.close();
  });

  blocTest<DataLocationBloc, DataLocationState>(
    'emits updated state when resetting to default',
    build: () => bloc,
    setUp: () {
      when(() => repository.resetUserDataLocation()).thenAnswer(
        (_) async => FlowyResult.success(
          UserDataLocation(path: defaultPath, isCustom: false),
        ),
      );
    },
    act: (bloc) => bloc.add(DataLocationEvent.resetToDefault()),
    wait: const Duration(milliseconds: 100),
    expect: () => [
      DataLocationState(
        userDataLocation: UserDataLocation(path: defaultPath, isCustom: false),
        didResetToDefault: true,
      ),
    ],
  );

  blocTest<DataLocationBloc, DataLocationState>(
    'emits updated state when setting custom path',
    build: () => bloc,
    setUp: () {
      when(() => repository.setCustomLocation(customPath)).thenAnswer(
        (_) async => FlowyResult.success(
          UserDataLocation(path: customPath, isCustom: true),
        ),
      );
    },
    act: (bloc) => bloc.add(DataLocationEvent.setCustomPath(customPath)),
    wait: const Duration(milliseconds: 100),
    expect: () => [
      DataLocationState(
        userDataLocation: UserDataLocation(path: customPath, isCustom: true),
        didResetToDefault: false,
      ),
    ],
  );

  blocTest<DataLocationBloc, DataLocationState>(
    'emits state with cleared reset flag',
    build: () => bloc,
    seed: () => DataLocationState(
      userDataLocation: UserDataLocation(path: defaultPath, isCustom: false),
      didResetToDefault: true,
    ),
    act: (bloc) => bloc.add(DataLocationEvent.clearState()),
    wait: const Duration(milliseconds: 100),
    expect: () => [
      DataLocationState(
        userDataLocation: UserDataLocation(
          path: defaultPath,
          isCustom: false,
        ),
        didResetToDefault: false,
      ),
    ],
  );
}
