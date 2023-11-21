import 'package:appflowy/plugins/database_view/application/defines.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

import 'cloud_setting_listener.dart';

part 'cloud_setting_bloc.freezed.dart';

class AppFlowyCloudSettingBloc
    extends Bloc<AppFlowyCloudSettingEvent, AppFlowyCloudSettingState> {
  final UserCloudConfigListener _listener;

  AppFlowyCloudSettingBloc({
    required String userId,
    required AppFlowyCloudSettingPB config,
  })  : _listener = UserCloudConfigListener(userId: userId),
        super(AppFlowyCloudSettingState.initial(config)) {
    on<AppFlowyCloudSettingEvent>((event, emit) async {
      await event.when(
        initial: () async {
          _listener.start(
            onSettingChanged: (result) {
              if (isClosed) {
                return;
              }

              result.fold(
                (config) =>
                    add(AppFlowyCloudSettingEvent.didReceiveConfig(config)),
                (error) => Log.error(error),
              );
            },
          );
        },
        didReceiveConfig: (CloudSettingPB config) {
          emit(
            state.copyWith(
              config: config,
              loadingState: LoadingState.finish(left(unit)),
            ),
          );
        },
      );
    });
  }

  Future<void> updateCloudConfig(UpdateCloudConfigPB config) async {
    await UserEventSetCloudConfig(config).send();
  }
}

@freezed
class AppFlowyCloudSettingEvent with _$AppFlowyCloudSettingEvent {
  const factory AppFlowyCloudSettingEvent.initial() = _Initial;
  const factory AppFlowyCloudSettingEvent.didReceiveConfig(
    CloudSettingPB config,
  ) = _DidSyncSupabaseConfig;
}

@freezed
class AppFlowyCloudSettingState with _$AppFlowyCloudSettingState {
  const factory AppFlowyCloudSettingState({
    required AppFlowyCloudSettingPB config,
    required Either<Unit, String> successOrFailure,
    required LoadingState loadingState,
  }) = _AppFlowyCloudSettingState;

  factory AppFlowyCloudSettingState.initial(AppFlowyCloudSettingPB config) =>
      AppFlowyCloudSettingState(
        config: config,
        successOrFailure: left(unit),
        loadingState: LoadingState.finish(left(unit)),
      );
}
