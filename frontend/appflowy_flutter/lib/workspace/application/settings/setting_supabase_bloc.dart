import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
import 'package:protobuf/protobuf.dart';

part 'setting_supabase_bloc.freezed.dart';

class SettingSupabaseBloc
    extends Bloc<SettingSupabaseEvent, SettingSupabaseState> {
  SettingSupabaseBloc() : super(SettingSupabaseState.initial()) {
    on<SettingSupabaseEvent>((event, emit) async {
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
        didReceiveSupabseConfig: (SupabaseConfigPB config) {
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
          add(SettingSupabaseEvent.didReceiveSupabseConfig(config));
        }
      },
      (r) => Log.error(r),
    );
  }
}

@freezed
class SettingSupabaseEvent with _$SettingSupabaseEvent {
  const factory SettingSupabaseEvent.initial() = _Initial;
  const factory SettingSupabaseEvent.didReceiveSupabseConfig(
    SupabaseConfigPB config,
  ) = _DidReceiveSupabaseConfig;
  const factory SettingSupabaseEvent.enableSync(bool enable) = _EnableSync;
}

@freezed
class SettingSupabaseState with _$SettingSupabaseState {
  const factory SettingSupabaseState({
    SupabaseConfigPB? config,
    required Either<Unit, String> successOrFailure,
  }) = _SettingSupabaseState;

  factory SettingSupabaseState.initial() => SettingSupabaseState(
        successOrFailure: left(unit),
      );
}
