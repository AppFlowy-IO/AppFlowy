import 'package:appflowy/env/backend_env.dart';
import 'package:appflowy/env/env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

part 'cloud_setting_bloc.freezed.dart';

class AppFlowyCloudSettingBloc
    extends Bloc<AppFlowyCloudSettingEvent, AppFlowyCloudSettingState> {
  AppFlowyCloudSettingBloc() : super(AppFlowyCloudSettingState.initial()) {
    on<AppFlowyCloudSettingEvent>((event, emit) async {
      await event.when(
        initial: () async {},
        updateServerUrl: (text) {
          emit(state.copyWith(updatedServerUrl: text));
        },
        updateWebsocketUrl: (text) {
          emit(state.copyWith(updatedWebsocketUrl: text));
        },
        confirmUpdate: () async {
          //

          await setAppFlowyCloudBaseUrl(state.updatedServerUrl);
          await setAppFlowyCloudWSUrl(state.updatedWebsocketUrl);
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
  const factory AppFlowyCloudSettingEvent.updateServerUrl(String text) =
      _ServerUrl;
  const factory AppFlowyCloudSettingEvent.updateWebsocketUrl(String text) =
      _WebsocketUrl;
  const factory AppFlowyCloudSettingEvent.confirmUpdate() = _UpdateConfig;
}

@freezed
class AppFlowyCloudSettingState with _$AppFlowyCloudSettingState {
  const factory AppFlowyCloudSettingState({
    required AppFlowyCloudConfiguration config,
    required String updatedServerUrl,
    required String updatedWebsocketUrl,
    required Either<Unit, String> successOrFailure,
  }) = _AppFlowyCloudSettingState;

  factory AppFlowyCloudSettingState.initial() => AppFlowyCloudSettingState(
        config: getIt<AppFlowyCloudSharedEnv>().appflowyCloudConfig,
        successOrFailure: left(unit),
        updatedServerUrl: '',
        updatedWebsocketUrl: '',
      );
}
