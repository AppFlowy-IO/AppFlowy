import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/settings_repository.dart';
import 'data_location_event.dart';
import 'data_location_state.dart';

class DataLocationBloc extends Bloc<DataLocationEvent, DataLocationState> {
  DataLocationBloc({
    required SettingsRepository repository,
  })  : _repository = repository,
        super(DataLocationState.initial()) {
    on<DataLocationInitial>(_onStarted);
    on<DataLocationResetToDefault>(_onResetToDefault);
    on<DataLocationSetCustomPath>(_onSetCustomPath);
    on<DataLocationClearState>(_onClearState);
  }

  final SettingsRepository _repository;

  Future<void> _onStarted(
    DataLocationInitial event,
    Emitter<DataLocationState> emit,
  ) async {
    final userDataLocation =
        await _repository.getUserDataLocation().toNullable();

    emit(
      DataLocationState(
        userDataLocation: userDataLocation,
        didResetToDefault: false,
      ),
    );
  }

  Future<void> _onResetToDefault(
    DataLocationResetToDefault event,
    Emitter<DataLocationState> emit,
  ) async {
    final defaultLocation =
        await _repository.resetUserDataLocation().toNullable();

    emit(
      DataLocationState(
        userDataLocation: defaultLocation,
        didResetToDefault: true,
      ),
    );
  }

  Future<void> _onClearState(
    DataLocationClearState event,
    Emitter<DataLocationState> emit,
  ) async {
    emit(
      state.copyWith(
        didResetToDefault: false,
      ),
    );
  }

  Future<void> _onSetCustomPath(
    DataLocationSetCustomPath event,
    Emitter<DataLocationState> emit,
  ) async {
    final userDataLocation =
        await _repository.setCustomLocation(event.path).toNullable();

    emit(
      state.copyWith(
        userDataLocation: userDataLocation,
        didResetToDefault: false,
      ),
    );
  }
}
