import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/workspace/welcome_bloc.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';

import 'util/test_env.dart';

void main() {
  UserProfilePB? userInfo;
  setUpAll(() async {
    final flowyTest = await FlowyTest.setup();
    userInfo = await flowyTest.signIn();
  });

  group('WelcomeBloc', () {
    blocTest<WelcomeBloc, WelcomeState>(
      "welcome screen init",
      build: () => getIt<WelcomeBloc>(param1: userInfo),
      act: (bloc) {
        bloc.add(const WelcomeEvent.initial());
      },
      wait: const Duration(seconds: 3),
      verify: (bloc) {
        assert(bloc.state.isLoading == false);
      },
    );
  });
}
