import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
import 'package:protobuf/protobuf.dart';

part 'setting_supabase_bloc.freezed.dart';

class SyncSettingBloc extends Bloc<SyncSettingEvent, SyncSettingState> {
  SyncSettingBloc() : super(SyncSettingState.initial()) {
    on<SyncSettingEvent>((event, emit) async {
      await event.when(
        initial: () async {
          await getSupabaseConfig();
        },
        enableSync: (bool enable) async {
          final oldConfig = state.config;
          if (oldConfig != null) {
            oldConfig.freeze();
            final newConfig = oldConfig.rebuild((config) {
              config.enableSync = enable;
            });
            updateSupabaseConfig(newConfig);
            emit(state.copyWith(config: newConfig));
          }
        },
        didReceiveSyncConfig: (SupabaseConfigPB config) {
          emit(state.copyWith(config: config));
        },
      );
    });
  }

  Future<void> updateSupabaseConfig(SupabaseConfigPB config) async {
    await UserEventSetSupabaseConfig(config).send();
  }

  Future<void> getSupabaseConfig() async {
    final result = await UserEventGetSupabaseConfig().send();
    result.fold(
      (config) {
        if (!isClosed) {
          add(SyncSettingEvent.didReceiveSyncConfig(config));
        }
      },
      (r) => Log.error(r),
    );
  }
}

@freezed
class SyncSettingEvent with _$SyncSettingEvent {
  const factory SyncSettingEvent.initial() = _Initial;
  const factory SyncSettingEvent.didReceiveSyncConfig(
    SupabaseConfigPB config,
  ) = _DidSyncSupabaseConfig;
  const factory SyncSettingEvent.enableSync(bool enable) = _EnableSync;
}

@freezed
class SyncSettingState with _$SyncSettingState {
  const factory SyncSettingState({
    SupabaseConfigPB? config,
    required Either<Unit, String> successOrFailure,
  }) = _SyncSettingState;

  factory SyncSettingState.initial() => SyncSettingState(
        successOrFailure: left(unit),
      );
}
