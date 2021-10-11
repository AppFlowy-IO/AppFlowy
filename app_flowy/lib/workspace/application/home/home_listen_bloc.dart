import 'package:app_flowy/workspace/domain/i_user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
part 'home_listen_bloc.freezed.dart';

class HomeListenBloc extends Bloc<HomeListenEvent, HomeListenState> {
  final IUserListener listener;
  HomeListenBloc(this.listener) : super(const HomeListenState.loading());

  @override
  Stream<HomeListenState> mapEventToState(
    HomeListenEvent event,
  ) async* {
    yield* event.map(
      started: (_) async* {
        listener.setAuthCallback(_authStateChanged);
        listener.start();
      },
      stop: (_) async* {},
      unauthorized: (e) async* {
        yield HomeListenState.unauthorized(e.msg);
      },
    );
  }

  @override
  Future<void> close() async {
    await listener.stop();
    super.close();
  }

  void _authStateChanged(Either<Unit, UserError> errorOrNothing) {
    errorOrNothing.fold((_) {}, (error) {
      if (error.code == ErrorCode.UserUnauthorized) {
        add(HomeListenEvent.unauthorized(error.msg));
      }
    });
  }
}

@freezed
class HomeListenEvent with _$HomeListenEvent {
  const factory HomeListenEvent.started() = _Started;
  const factory HomeListenEvent.stop() = _Stop;
  const factory HomeListenEvent.unauthorized(String msg) = _Unauthorized;
}

@freezed
class HomeListenState with _$HomeListenState {
  const factory HomeListenState.loading() = Loading;
  const factory HomeListenState.unauthorized(String msg) = Unauthorized;
}
