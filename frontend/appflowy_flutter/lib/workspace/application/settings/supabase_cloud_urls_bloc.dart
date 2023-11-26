import 'package:appflowy/env/backend_env.dart';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

import 'appflowy_cloud_setting_bloc.dart';

part 'supabase_cloud_urls_bloc.freezed.dart';

class SupabaseCloudURLsBloc
    extends Bloc<SupabaseCloudURLsEvent, SupabaseCloudURLsState> {
  SupabaseCloudURLsBloc() : super(SupabaseCloudURLsState.initial()) {
    on<SupabaseCloudURLsEvent>((event, emit) async {
      await event.when(
        updateUrl: (String url) {
          emit(state.copyWith(updatedUrl: url));
        },
        updateAnonKey: (String anonKey) {
          emit(state.copyWith(upatedAnonKey: anonKey));
        },
        confirmUpdate: () async {
          if (state.updatedUrl.isEmpty) {
            emit(
              state.copyWith(
                urlError: none(),
                anonKeyError: none(),
                restartApp: true,
              ),
            );
            await setSupbaseServer(none(), none());
          } else {
            // The anon key can't be empty if the url is not empty.
            if (state.upatedAnonKey.isEmpty) {
              emit(
                state.copyWith(
                  urlError: none(),
                  anonKeyError: some(
                    LocaleKeys.settings_menu_cloudSupabaseAnonKeyCanNotBeEmpty
                        .tr(),
                  ),
                  restartApp: false,
                ),
              );
              return;
            }

            validateUrl(state.updatedUrl).fold(
              (error) => emit(state.copyWith(urlError: Some(error))),
              (_) async {
                await setSupbaseServer(
                  Some(state.updatedUrl),
                  Some(state.upatedAnonKey),
                );

                add(const SupabaseCloudURLsEvent.didSaveConfig());
              },
            );
          }
        },
        didSaveConfig: () {
          emit(
            state.copyWith(
              urlError: none(),
              anonKeyError: none(),
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
    required Option<String> urlError,
    required Option<String> anonKeyError,
    required bool restartApp,
  }) = _SupabaseCloudURLsState;

  factory SupabaseCloudURLsState.initial() {
    final config = getIt<AppFlowyCloudSharedEnv>().supabaseConfig;
    return SupabaseCloudURLsState(
      updatedUrl: config.url,
      upatedAnonKey: config.anon_key,
      urlError: none(),
      anonKeyError: none(),
      restartApp: false,
      config: config,
    );
  }
}
