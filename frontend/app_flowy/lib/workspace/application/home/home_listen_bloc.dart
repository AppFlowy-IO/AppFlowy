import 'package:app_flowy/workspace/domain/i_user.dart';
import 'package:flowy_sdk/protobuf/flowy-core-data-model/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
part 'home_listen_bloc.freezed.dart';

class HomeListenBloc extends Bloc<HomeListenEvent, HomeListenState> {
  final IUserListener listener;
  HomeListenBloc(this.listener) : super(const HomeListenState.loading()) {
    on<HomeListenEvent>((event, emit) async {
      await event.map(
        started: (_) async {
          listener.authDidChangedNotifier.addPublishListener((result) {
            _authDidChanged(result);
          });
          listener.start();
        },
        stop: (_) async {},
        unauthorized: (e) async {
          emit(HomeListenState.unauthorized(e.msg));
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await listener.stop();
    super.close();
  }

  void _authDidChanged(Either<Unit, FlowyError> errorOrNothing) {
    errorOrNothing.fold((_) {}, (error) {
      if (error.code == ErrorCode.UserUnauthorized.value) {
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
