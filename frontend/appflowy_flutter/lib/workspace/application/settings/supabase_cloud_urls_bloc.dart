import 'package:appflowy/env/backend_env.dart';
import 'package:appflowy/env/env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
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
          try {
            validateUrl(state.updatedUrl).fold(
              (error) => emit(state.copyWith(urlError: Some(error))),
              (_) async {
                if (state.config.url != state.updatedUrl ||
                    state.config.anon_key != state.upatedAnonKey) {
                  await setSupbaseServer(
                    Some(state.updatedUrl),
                    Some(state.upatedAnonKey),
                  );
                  emit(
                    state.copyWith(
                      urlError: none(),
                      anonKeyError: none(),
                      restartApp: true,
                    ),
                  );
                }
              },
            );
          } catch (e) {
            emit(
              state.copyWith(urlError: Some(e.toString())),
            );
          }
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

  factory SupabaseCloudURLsState.initial() => SupabaseCloudURLsState(
        updatedUrl: '',
        upatedAnonKey: '',
        urlError: none(),
        anonKeyError: none(),
        restartApp: false,
        config: getIt<AppFlowyCloudSharedEnv>().supabaseConfig,
      );
}
