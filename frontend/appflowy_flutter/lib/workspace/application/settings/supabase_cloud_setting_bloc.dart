import 'package:appflowy/env/backend_env.dart';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/plugins/database/application/defines.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'cloud_setting_listener.dart';

part 'supabase_cloud_setting_bloc.freezed.dart';

class SupabaseCloudSettingBloc
    extends Bloc<SupabaseCloudSettingEvent, SupabaseCloudSettingState> {
  SupabaseCloudSettingBloc({
    required CloudSettingPB setting,
  })  : _listener = UserCloudConfigListener(),
        super(SupabaseCloudSettingState.initial(setting)) {
    _dispatch();
  }

  final UserCloudConfigListener _listener;

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }

  void _dispatch() {
    on<SupabaseCloudSettingEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _listener.start(
              onSettingChanged: (result) {
                if (isClosed) {
                  return;
                }
                result.fold(
                  (setting) =>
                      add(SupabaseCloudSettingEvent.didReceiveSetting(setting)),
                  (error) => Log.error(error),
                );
              },
            );
          },
          enableSync: (bool enable) async {
            final update = UpdateCloudConfigPB.create()..enableSync = enable;
            await updateCloudConfig(update);
          },
          didReceiveSetting: (CloudSettingPB setting) {
            emit(
              state.copyWith(
                setting: setting,
                loadingState: LoadingState.finish(FlowyResult.success(null)),
              ),
            );
          },
          enableEncrypt: (bool enable) {
            final update = UpdateCloudConfigPB.create()..enableEncrypt = enable;
            updateCloudConfig(update);
            emit(state.copyWith(loadingState: const LoadingState.loading()));
          },
        );
      },
    );
  }

  Future<void> updateCloudConfig(UpdateCloudConfigPB setting) async {
    await UserEventSetCloudConfig(setting).send();
  }
}

@freezed
class SupabaseCloudSettingEvent with _$SupabaseCloudSettingEvent {
  const factory SupabaseCloudSettingEvent.initial() = _Initial;
  const factory SupabaseCloudSettingEvent.didReceiveSetting(
    CloudSettingPB setting,
  ) = _DidSyncSupabaseConfig;
  const factory SupabaseCloudSettingEvent.enableSync(bool enable) = _EnableSync;
  const factory SupabaseCloudSettingEvent.enableEncrypt(bool enable) =
      _EnableEncrypt;
}

@freezed
class SupabaseCloudSettingState with _$SupabaseCloudSettingState {
  const factory SupabaseCloudSettingState({
    required LoadingState loadingState,
    required SupabaseConfiguration config,
    required CloudSettingPB setting,
  }) = _SupabaseCloudSettingState;

  factory SupabaseCloudSettingState.initial(CloudSettingPB setting) =>
      SupabaseCloudSettingState(
        loadingState: LoadingState.finish(FlowyResult.success(null)),
        setting: setting,
        config: getIt<AppFlowyCloudSharedEnv>().supabaseConfig,
      );
}
