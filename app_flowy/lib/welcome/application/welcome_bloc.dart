import 'package:app_flowy/welcome/domain/auth_state.dart';
import 'package:app_flowy/welcome/domain/interface.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'welcome_event.dart';
part 'welcome_state.dart';
part 'welcome_bloc.freezed.dart';

class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  final IWelcomeAuth authImpl;
  WelcomeBloc(this.authImpl) : super(WelcomeState.initial());

  @override
  Stream<WelcomeState> mapEventToState(WelcomeEvent event) async* {
    yield* event.map(
      getUser: (val) async* {
        final authState = await authImpl.currentUserState();
        yield state.copyWith(auth: authState);
      },
    );
  }
}
