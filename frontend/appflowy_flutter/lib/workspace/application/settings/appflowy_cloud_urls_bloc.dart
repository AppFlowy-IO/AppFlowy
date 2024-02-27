import 'package:appflowy/env/backend_env.dart';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'appflowy_cloud_urls_bloc.freezed.dart';

class AppFlowyCloudURLsBloc
    extends Bloc<AppFlowyCloudURLsEvent, AppFlowyCloudURLsState> {
  AppFlowyCloudURLsBloc() : super(AppFlowyCloudURLsState.initial()) {
    on<AppFlowyCloudURLsEvent>((event, emit) async {
      await event.when(
        initial: () async {},
        updateServerUrl: (url) {
          emit(
            state.copyWith(
              updatedServerUrl: url,
              urlError: null,
              showRestartHint: url.isNotEmpty,
            ),
          );
        },
        confirmUpdate: () async {
          if (state.updatedServerUrl.isEmpty) {
            emit(
              state.copyWith(
                updatedServerUrl: "",
                urlError:
                    LocaleKeys.settings_menu_appFlowyCloudUrlCanNotBeEmpty.tr(),
                restartApp: false,
              ),
            );
          } else {
            validateUrl(state.updatedServerUrl).fold(
              (url) async {
                await useSelfHostedAppFlowyCloudWithURL(url);
                add(const AppFlowyCloudURLsEvent.didSaveConfig());
              },
              (err) => emit(state.copyWith(urlError: err)),
            );
          }
        },
        didSaveConfig: () {
          emit(
            state.copyWith(
              urlError: null,
              restartApp: true,
            ),
          );
        },
      );
    });
  }
}

@freezed
class AppFlowyCloudURLsEvent with _$AppFlowyCloudURLsEvent {
  const factory AppFlowyCloudURLsEvent.initial() = _Initial;
  const factory AppFlowyCloudURLsEvent.updateServerUrl(String text) =
      _ServerUrl;
  const factory AppFlowyCloudURLsEvent.confirmUpdate() = _UpdateConfig;
  const factory AppFlowyCloudURLsEvent.didSaveConfig() = _DidSaveConfig;
}

@freezed
class AppFlowyCloudURLsState with _$AppFlowyCloudURLsState {
  const factory AppFlowyCloudURLsState({
    required AppFlowyCloudConfiguration config,
    required String updatedServerUrl,
    required String? urlError,
    required bool restartApp,
    required bool showRestartHint,
  }) = _AppFlowyCloudURLsState;

  factory AppFlowyCloudURLsState.initial() => AppFlowyCloudURLsState(
        config: getIt<AppFlowyCloudSharedEnv>().appflowyCloudConfig,
        urlError: null,
        updatedServerUrl:
            getIt<AppFlowyCloudSharedEnv>().appflowyCloudConfig.base_url,
        showRestartHint: getIt<AppFlowyCloudSharedEnv>()
            .appflowyCloudConfig
            .base_url
            .isNotEmpty,
        restartApp: false,
      );
}

FlowyResult<String, String> validateUrl(String url) {
  try {
    // Use Uri.parse to validate the url.
    final uri = Uri.parse(removeTrailingSlash(url));
    if (uri.isScheme('HTTP') || uri.isScheme('HTTPS')) {
      return FlowyResult.success(uri.toString());
    } else {
      return FlowyResult.failure(
        LocaleKeys.settings_menu_invalidCloudURLScheme.tr(),
      );
    }
  } catch (e) {
    return FlowyResult.failure(e.toString());
  }
}

String removeTrailingSlash(String input) {
  if (input.endsWith('/')) {
    return input.substring(0, input.length - 1);
  }
  return input;
}
