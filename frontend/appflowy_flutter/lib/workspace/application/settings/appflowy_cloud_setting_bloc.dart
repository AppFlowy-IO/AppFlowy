import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/cloud_setting_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'appflowy_cloud_setting_bloc.freezed.dart';

class AppFlowyCloudSettingBloc
    extends Bloc<AppFlowyCloudSettingEvent, AppFlowyCloudSettingState> {
  AppFlowyCloudSettingBloc(CloudSettingPB setting)
      : _listener = UserCloudConfigListener(),
        super(AppFlowyCloudSettingState.initial(setting, false)) {
    _dispatch();
    _getWorkspaceType();
  }

  final UserCloudConfigListener _listener;

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }

  void _getWorkspaceType() {
    UserEventGetUserProfile().send().then((value) {
      if (isClosed) {
        return;
      }

      value.fold(
        (profile) => add(
          AppFlowyCloudSettingEvent.workspaceTypeChanged(
            profile.workspaceType,
          ),
        ),
        (error) => Log.error(error),
      );
    });
  }

  void _dispatch() {
    on<AppFlowyCloudSettingEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            await getSyncLogEnabled().then((value) {
              emit(state.copyWith(isSyncLogEnabled: value));
            });

            _listener.start(
              onSettingChanged: (result) {
                if (isClosed) {
                  return;
                }
                result.fold(
                  (setting) =>
                      add(AppFlowyCloudSettingEvent.didReceiveSetting(setting)),
                  (error) => Log.error(error),
                );
              },
            );
          },
          enableSync: (isEnable) async {
            final config = UpdateCloudConfigPB.create()..enableSync = isEnable;
            await UserEventSetCloudConfig(config).send();
          },
          enableSyncLog: (isEnable) async {
            await setSyncLogEnabled(isEnable);
            emit(state.copyWith(isSyncLogEnabled: isEnable));
          },
          didReceiveSetting: (CloudSettingPB setting) {
            emit(
              state.copyWith(
                setting: setting,
                showRestartHint: setting.serverUrl.isNotEmpty,
              ),
            );
          },
          workspaceTypeChanged: (WorkspaceTypePB workspaceType) {
            emit(state.copyWith(workspaceType: workspaceType));
          },
        );
      },
    );
  }
}

@freezed
class AppFlowyCloudSettingEvent with _$AppFlowyCloudSettingEvent {
  const factory AppFlowyCloudSettingEvent.initial() = _Initial;
  const factory AppFlowyCloudSettingEvent.enableSync(bool isEnable) =
      _EnableSync;
  const factory AppFlowyCloudSettingEvent.enableSyncLog(bool isEnable) =
      _EnableSyncLog;
  const factory AppFlowyCloudSettingEvent.didReceiveSetting(
    CloudSettingPB setting,
  ) = _DidUpdateSetting;
  const factory AppFlowyCloudSettingEvent.workspaceTypeChanged(
    WorkspaceTypePB workspaceType,
  ) = _WorkspaceTypeChanged;
}

@freezed
class AppFlowyCloudSettingState with _$AppFlowyCloudSettingState {
  const factory AppFlowyCloudSettingState({
    required CloudSettingPB setting,
    required bool showRestartHint,
    required bool isSyncLogEnabled,
    required WorkspaceTypePB workspaceType,
  }) = _AppFlowyCloudSettingState;

  factory AppFlowyCloudSettingState.initial(
    CloudSettingPB setting,
    bool isSyncLogEnabled,
  ) =>
      AppFlowyCloudSettingState(
        setting: setting,
        showRestartHint: setting.serverUrl.isNotEmpty,
        isSyncLogEnabled: isSyncLogEnabled,
        workspaceType: WorkspaceTypePB.ServerW,
      );
}

FlowyResult<void, String> validateUrl(String url) {
  try {
    // Use Uri.parse to validate the url.
    final uri = Uri.parse(url);
    if (uri.isScheme('HTTP') || uri.isScheme('HTTPS')) {
      return FlowyResult.success(null);
    } else {
      return FlowyResult.failure(
        LocaleKeys.settings_menu_invalidCloudURLScheme.tr(),
      );
    }
  } catch (e) {
    return FlowyResult.failure(e.toString());
  }
}
