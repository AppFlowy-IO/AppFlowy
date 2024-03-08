import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/cloud_setting_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'appflowy_cloud_setting_bloc.freezed.dart';

class AppFlowyCloudSettingBloc
    extends Bloc<AppFlowyCloudSettingEvent, AppFlowyCloudSettingState> {
  AppFlowyCloudSettingBloc(CloudSettingPB setting)
      : _listener = UserCloudConfigListener(),
        super(AppFlowyCloudSettingState.initial(setting)) {
    _dispatch();
  }

  final UserCloudConfigListener _listener;

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }

  void _dispatch() {
    on<AppFlowyCloudSettingEvent>(
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
          didReceiveSetting: (CloudSettingPB setting) {
            emit(
              state.copyWith(
                setting: setting,
                showRestartHint: setting.serverUrl.isNotEmpty,
              ),
            );
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
  const factory AppFlowyCloudSettingEvent.didReceiveSetting(
    CloudSettingPB setting,
  ) = _DidUpdateSetting;
}

@freezed
class AppFlowyCloudSettingState with _$AppFlowyCloudSettingState {
  const factory AppFlowyCloudSettingState({
    required CloudSettingPB setting,
    required bool showRestartHint,
  }) = _AppFlowyCloudSettingState;

  factory AppFlowyCloudSettingState.initial(CloudSettingPB setting) =>
      AppFlowyCloudSettingState(
        setting: setting,
        showRestartHint: setting.serverUrl.isNotEmpty,
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
