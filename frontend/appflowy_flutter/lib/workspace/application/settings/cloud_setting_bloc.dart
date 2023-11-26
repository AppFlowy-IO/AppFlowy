import 'package:appflowy/env/cloud_env.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cloud_setting_bloc.freezed.dart';

class CloudSettingBloc extends Bloc<CloudSettingEvent, CloudSettingState> {
  CloudSettingBloc(CloudType cloudType)
      : super(CloudSettingState.initial(cloudType)) {
    on<CloudSettingEvent>((event, emit) async {
      await event.when(
        initial: () async {},
        updateCloudType: (CloudType newCloudType) async {
          await setCloudType(newCloudType);
          emit(state.copyWith(cloudType: newCloudType));
        },
      );
    });
  }
}

@freezed
class CloudSettingEvent with _$CloudSettingEvent {
  const factory CloudSettingEvent.initial() = _Initial;
  const factory CloudSettingEvent.updateCloudType(CloudType newCloudType) =
      _UpdateCloudType;
}

@freezed
class CloudSettingState with _$CloudSettingState {
  const factory CloudSettingState({
    required CloudType cloudType,
  }) = _CloudSettingState;

  factory CloudSettingState.initial(CloudType cloudType) => CloudSettingState(
        cloudType: cloudType,
      );
}
