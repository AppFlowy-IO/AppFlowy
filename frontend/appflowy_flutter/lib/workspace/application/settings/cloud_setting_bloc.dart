import 'package:appflowy/env/backend_env.dart';
import 'package:appflowy/env/env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

part 'cloud_setting_bloc.freezed.dart';

class AppFlowyCloudSettingBloc
    extends Bloc<AppFlowyCloudSettingEvent, AppFlowyCloudSettingState> {
  AppFlowyCloudSettingBloc(CloudSettingPB setting)
      : super(AppFlowyCloudSettingState.initial(setting)) {
    on<AppFlowyCloudSettingEvent>((event, emit) async {
      await event.when(
        initial: () async {},
        updateServerUrl: (url) {
          emit(state.copyWith(updatedServerUrl: url));
        },
        confirmUpdate: () async {
          if (state.updatedServerUrl.isEmpty) {
            await setAppFlowyCloudBaseUrl(none());
            emit(
              state.copyWith(
                updatedServerUrl: "",
                urlError: none(),
                restartApp: true,
              ),
            );
          } else {
            try {
              // Use Uri.parse to validate the url.
              // ignore: unused_local_variable
              final uri = Uri.parse(state.updatedServerUrl);

              if (uri.isScheme('HTTP') || uri.isScheme('HTTPS')) {
                if (state.config.base_url != state.updatedServerUrl) {
                  await setAppFlowyCloudBaseUrl(Some(state.updatedServerUrl));
                  emit(
                    state.copyWith(
                      updatedServerUrl: state.updatedServerUrl,
                      urlError: none(),
                      restartApp: true,
                    ),
                  );
                } else {
                  emit(
                    state.copyWith(
                      urlError: const Some('URL is the same'),
                    ),
                  );
                }
              } else {
                emit(
                  state.copyWith(
                    urlError: const Some('Invalid Schema'),
                  ),
                );
              }
            } catch (e) {
              emit(
                state.copyWith(
                  urlError: Some(e.toString()),
                ),
              );
            }
          }
        },
        enableSync: (isEnable) async {
          final config = UpdateCloudConfigPB.create()..enableEncrypt = isEnable;
          await UserEventSetCloudConfig(config).send();
        },
      );
    });
  }
}

@freezed
class AppFlowyCloudSettingEvent with _$AppFlowyCloudSettingEvent {
  const factory AppFlowyCloudSettingEvent.initial() = _Initial;
  const factory AppFlowyCloudSettingEvent.updateServerUrl(String text) =
      _ServerUrl;
  const factory AppFlowyCloudSettingEvent.confirmUpdate() = _UpdateConfig;
  const factory AppFlowyCloudSettingEvent.enableSync(bool isEnable) =
      _EnableSync;
}

@freezed
class AppFlowyCloudSettingState with _$AppFlowyCloudSettingState {
  const factory AppFlowyCloudSettingState({
    required AppFlowyCloudConfiguration config,
    required CloudSettingPB setting,
    required String updatedServerUrl,
    required String updatedWebsocketUrl,
    required Option<String> urlError,
    required bool restartApp,
  }) = _AppFlowyCloudSettingState;

  factory AppFlowyCloudSettingState.initial(CloudSettingPB setting) =>
      AppFlowyCloudSettingState(
        config: getIt<AppFlowyCloudSharedEnv>().appflowyCloudConfig,
        urlError: none(),
        updatedServerUrl:
            getIt<AppFlowyCloudSharedEnv>().appflowyCloudConfig.base_url,
        updatedWebsocketUrl: '',
        setting: setting,
        restartApp: false,
      );
}
