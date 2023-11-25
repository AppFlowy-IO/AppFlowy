import 'package:appflowy/env/backend_env.dart';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

part 'appflowy_cloud_urls_bloc.freezed.dart';

class AppFlowyCloudURLsBloc
    extends Bloc<AppFlowyCloudURLsEvent, AppFlowyCloudURLsState> {
  AppFlowyCloudURLsBloc() : super(AppFlowyCloudURLsState.initial()) {
    on<AppFlowyCloudURLsEvent>((event, emit) async {
      await event.when(
        initial: () async {},
        updateServerUrl: (url) {
          emit(state.copyWith(updatedServerUrl: url));
        },
        confirmUpdate: () async {
          if (state.updatedServerUrl.isEmpty) {
            emit(
              state.copyWith(
                updatedServerUrl: "",
                urlError: none(),
                restartApp: true,
              ),
            );
            await setAppFlowyCloudUrl(none());
          } else {
            validateUrl(state.updatedServerUrl).fold(
              (error) => emit(state.copyWith(urlError: Some(error))),
              (_) async {
                if (state.config.base_url != state.updatedServerUrl) {
                  await setAppFlowyCloudUrl(Some(state.updatedServerUrl));
                }
                add(const AppFlowyCloudURLsEvent.didSaveConfig());
              },
            );
          }
        },
        didSaveConfig: () {
          emit(
            state.copyWith(
              urlError: none(),
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
    required Option<String> urlError,
    required bool restartApp,
  }) = _AppFlowyCloudURLsState;

  factory AppFlowyCloudURLsState.initial() => AppFlowyCloudURLsState(
        config: getIt<AppFlowyCloudSharedEnv>().appflowyCloudConfig,
        urlError: none(),
        updatedServerUrl:
            getIt<AppFlowyCloudSharedEnv>().appflowyCloudConfig.base_url,
        restartApp: false,
      );
}

Either<String, ()> validateUrl(String url) {
  try {
    // Use Uri.parse to validate the url.
    final uri = Uri.parse(url);
    if (uri.isScheme('HTTP') || uri.isScheme('HTTPS')) {
      return right(());
    } else {
      return left(LocaleKeys.settings_menu_invalidCloudURLScheme.tr());
    }
  } catch (e) {
    return left(e.toString());
  }
}
