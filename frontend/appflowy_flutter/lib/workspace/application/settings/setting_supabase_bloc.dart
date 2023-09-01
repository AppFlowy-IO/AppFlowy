import 'package:appflowy/plugins/database_view/application/defines.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

import 'cloud_setting_listener.dart';

part 'setting_supabase_bloc.freezed.dart';

class CloudSettingBloc extends Bloc<CloudSettingEvent, CloudSettingState> {
  final UserCloudConfigListener _listener;

  CloudSettingBloc({
    required String userId,
    required UserCloudConfigPB config,
  })  : _listener = UserCloudConfigListener(userId: userId),
        super(CloudSettingState.initial(config)) {
    on<CloudSettingEvent>((event, emit) async {
      await event.when(
        initial: () async {
          _listener.start(
            onSettingChanged: (result) {
              if (isClosed) {
                return;
              }

              result.fold(
                (config) => add(CloudSettingEvent.didReceiveConfig(config)),
                (error) => Log.error(error),
              );
            },
          );
        },
        enableSync: (bool enable) async {
          final update = UpdateCloudConfigPB.create()..enableSync = enable;
          updateCloudConfig(update);
        },
        didReceiveConfig: (UserCloudConfigPB config) {
          emit(
            state.copyWith(
              config: config,
              loadingState: LoadingState.finish(left(unit)),
            ),
          );
        },
        enableEncrypt: (bool enable) {
          final update = UpdateCloudConfigPB.create()..enableEncrypt = enable;
          updateCloudConfig(update);
          emit(state.copyWith(loadingState: const LoadingState.loading()));
        },
      );
    });
  }

  Future<void> updateCloudConfig(UpdateCloudConfigPB config) async {
    await UserEventSetCloudConfig(config).send();
  }
}

@freezed
class CloudSettingEvent with _$CloudSettingEvent {
  const factory CloudSettingEvent.initial() = _Initial;
  const factory CloudSettingEvent.didReceiveConfig(
    UserCloudConfigPB config,
  ) = _DidSyncSupabaseConfig;
  const factory CloudSettingEvent.enableSync(bool enable) = _EnableSync;
  const factory CloudSettingEvent.enableEncrypt(bool enable) = _EnableEncrypt;
}

@freezed
class CloudSettingState with _$CloudSettingState {
  const factory CloudSettingState({
    required UserCloudConfigPB config,
    required Either<Unit, String> successOrFailure,
    required LoadingState loadingState,
  }) = _CloudSettingState;

  factory CloudSettingState.initial(UserCloudConfigPB config) =>
      CloudSettingState(
        config: config,
        successOrFailure: left(unit),
        loadingState: LoadingState.finish(left(unit)),
      );
}
