sealed class DataLocationEvent {
  const DataLocationEvent();

  factory DataLocationEvent.initial() = DataLocationInitial;

  factory DataLocationEvent.resetToDefault() = DataLocationResetToDefault;

  factory DataLocationEvent.clearState() = DataLocationClearState;
}

class DataLocationInitial extends DataLocationEvent {}

class DataLocationResetToDefault extends DataLocationEvent {}

class DataLocationClearState extends DataLocationEvent {}
