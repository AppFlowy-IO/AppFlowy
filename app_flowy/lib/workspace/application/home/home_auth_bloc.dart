import 'package:app_flowy/workspace/domain/i_user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
part 'home_auth_bloc.freezed.dart';

class HomeAuthBloc extends Bloc<HomeAuthEvent, HomeAuthState> {
  final IUserWatch watch;
  HomeAuthBloc(this.watch) : super(const HomeAuthState.loading());

  @override
  Stream<HomeAuthState> mapEventToState(
    HomeAuthEvent event,
  ) async* {
    yield* event.map(
      started: (_) async* {
        watch.setAuthCallback(_authStateChanged);
        watch.startWatching();
      },
      stop: (_) async* {},
      unauthorized: (e) async* {
        yield HomeAuthState.unauthorized(e.msg);
      },
    );
  }

  @override
  Future<void> close() async {
    await watch.stopWatching();
    super.close();
  }

  void _authStateChanged(Either<Unit, UserError> errorOrNothing) {
    errorOrNothing.fold((_) {}, (error) {
      if (error.code == ErrorCode.UserUnauthorized) {
        add(HomeAuthEvent.unauthorized(error.msg));
      }
    });
  }
}

@freezed
class HomeAuthEvent with _$HomeAuthEvent {
  const factory HomeAuthEvent.started() = _Started;
  const factory HomeAuthEvent.stop() = _Stop;
  const factory HomeAuthEvent.unauthorized(String msg) = _Unauthorized;
}

@freezed
class HomeAuthState with _$HomeAuthState {
  const factory HomeAuthState.loading() = Loading;
  const factory HomeAuthState.unauthorized(String msg) = Unauthorized;
}
