import 'package:app_flowy/welcome/domain/auth_state.dart';
import 'package:app_flowy/welcome/domain/deps.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'welcome_event.dart';
part 'welcome_state.dart';
part 'welcome_bloc.freezed.dart';

class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  final IWelcomeAuth authCheck;
  WelcomeBloc(this.authCheck) : super(WelcomeState.initial());

  @override
  Stream<WelcomeState> mapEventToState(WelcomeEvent event) async* {
    yield* event.map(
      check: (val) async* {
        add(const WelcomeEvent.authCheck());
        yield state;
      },
      authCheck: (val) async* {
        final authState = await authCheck.getAuthState();
        yield state.copyWith(auth: authState);
      },
    );
  }
}
