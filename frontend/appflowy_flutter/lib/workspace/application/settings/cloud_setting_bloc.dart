import 'package:appflowy/env/cloud_env.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cloud_setting_bloc.freezed.dart';

class CloudSettingBloc extends Bloc<CloudSettingEvent, CloudSettingState> {
  CloudSettingBloc(AuthenticatorType cloudType)
      : super(CloudSettingState.initial(cloudType)) {
    on<CloudSettingEvent>((event, emit) async {
      await event.when(
        initial: () async {},
        updateCloudType: (AuthenticatorType newCloudType) async {
          emit(state.copyWith(cloudType: newCloudType));
        },
      );
    });
  }
}

@freezed
class CloudSettingEvent with _$CloudSettingEvent {
  const factory CloudSettingEvent.initial() = _Initial;
  const factory CloudSettingEvent.updateCloudType(
    AuthenticatorType newCloudType,
  ) = _UpdateCloudType;
}

@freezed
class CloudSettingState with _$CloudSettingState {
  const factory CloudSettingState({
    required AuthenticatorType cloudType,
  }) = _CloudSettingState;

  factory CloudSettingState.initial(AuthenticatorType cloudType) =>
      CloudSettingState(
        cloudType: cloudType,
      );
}
