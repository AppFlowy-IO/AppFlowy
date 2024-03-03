import 'package:appflowy/env/backend_env.dart';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'appflowy_cloud_setting_bloc.dart';

part 'supabase_cloud_urls_bloc.freezed.dart';

class SupabaseCloudURLsBloc
    extends Bloc<SupabaseCloudURLsEvent, SupabaseCloudURLsState> {
  SupabaseCloudURLsBloc() : super(SupabaseCloudURLsState.initial()) {
    on<SupabaseCloudURLsEvent>((event, emit) async {
      await event.when(
        updateUrl: (String url) {
          emit(
            state.copyWith(
              updatedUrl: url,
              showRestartHint: url.isNotEmpty && state.upatedAnonKey.isNotEmpty,
              urlError: null,
            ),
          );
        },
        updateAnonKey: (String anonKey) {
          emit(
            state.copyWith(
              upatedAnonKey: anonKey,
              showRestartHint:
                  anonKey.isNotEmpty && state.updatedUrl.isNotEmpty,
              anonKeyError: null,
            ),
          );
        },
        confirmUpdate: () async {
          if (state.updatedUrl.isEmpty) {
            emit(
              state.copyWith(
                urlError:
                    LocaleKeys.settings_menu_cloudSupabaseUrlCanNotBeEmpty.tr(),
                anonKeyError: null,
                restartApp: false,
              ),
            );
            return;
          }

          if (state.upatedAnonKey.isEmpty) {
            emit(
              state.copyWith(
                urlError: null,
                anonKeyError: LocaleKeys
                    .settings_menu_cloudSupabaseAnonKeyCanNotBeEmpty
                    .tr(),
                restartApp: false,
              ),
            );
            return;
          }

          validateUrl(state.updatedUrl).fold(
            (_) async {
              await useSupabaseCloud(
                url: state.updatedUrl,
                anonKey: state.upatedAnonKey,
              );

              add(const SupabaseCloudURLsEvent.didSaveConfig());
            },
            (error) => emit(state.copyWith(urlError: error)),
          );
        },
        didSaveConfig: () {
          emit(
            state.copyWith(
              urlError: null,
              anonKeyError: null,
              restartApp: true,
            ),
          );
        },
      );
    });
  }

  Future<void> updateCloudConfig(UpdateCloudConfigPB setting) async {
    await UserEventSetCloudConfig(setting).send();
  }
}

@freezed
class SupabaseCloudURLsEvent with _$SupabaseCloudURLsEvent {
  const factory SupabaseCloudURLsEvent.updateUrl(String text) = _UpdateUrl;
  const factory SupabaseCloudURLsEvent.updateAnonKey(String text) =
      _UpdateAnonKey;
  const factory SupabaseCloudURLsEvent.confirmUpdate() = _UpdateConfig;
  const factory SupabaseCloudURLsEvent.didSaveConfig() = _DidSaveConfig;
}

@freezed
class SupabaseCloudURLsState with _$SupabaseCloudURLsState {
  const factory SupabaseCloudURLsState({
    required SupabaseConfiguration config,
    required String updatedUrl,
    required String upatedAnonKey,
    required String? urlError,
    required String? anonKeyError,
    required bool restartApp,
    required bool showRestartHint,
  }) = _SupabaseCloudURLsState;

  factory SupabaseCloudURLsState.initial() {
    final config = getIt<AppFlowyCloudSharedEnv>().supabaseConfig;
    return SupabaseCloudURLsState(
      updatedUrl: config.url,
      upatedAnonKey: config.anon_key,
      urlError: null,
      anonKeyError: null,
      restartApp: false,
      showRestartHint: config.url.isNotEmpty && config.anon_key.isNotEmpty,
      config: config,
    );
  }
}
