import 'package:app_flowy/welcome/domain/auth_state.dart';
import 'package:app_flowy/welcome/domain/i_welcome.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'welcome_bloc.freezed.dart';

class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  final IWelcomeAuth authImpl;
  WelcomeBloc(this.authImpl) : super(WelcomeState.initial());

  @override
  Stream<WelcomeState> mapEventToState(WelcomeEvent event) async* {
    yield* event.map(
      getUser: (val) async* {
        final authState = await authImpl.currentUserDetail();
        yield state.copyWith(auth: authState);
      },
    );
  }
}

@freezed
abstract class WelcomeEvent with _$WelcomeEvent {
  const factory WelcomeEvent.getUser() = _GetUser;
}

@freezed
abstract class WelcomeState implements _$WelcomeState {
  const factory WelcomeState({
    required AuthState auth,
  }) = _WelcomeState;

  factory WelcomeState.initial() => const WelcomeState(
        auth: AuthState.initial(),
      );
}
