sealed class DataLocationEvent {
  const DataLocationEvent();

  factory DataLocationEvent.initial() = DataLocationInitial;

  factory DataLocationEvent.resetToDefault() = DataLocationResetToDefault;
}

class DataLocationInitial extends DataLocationEvent {}

class DataLocationResetToDefault extends DataLocationEvent {}
