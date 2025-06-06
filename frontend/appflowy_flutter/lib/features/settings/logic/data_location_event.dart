sealed class DataLocationEvent {
  const DataLocationEvent();

  factory DataLocationEvent.initial() = DataLocationInitial;

  factory DataLocationEvent.resetToDefault() = DataLocationResetToDefault;

  factory DataLocationEvent.setCustomPath(String path) =
      DataLocationSetCustomPath;

  factory DataLocationEvent.clearState() = DataLocationClearState;
}

class DataLocationInitial extends DataLocationEvent {}

class DataLocationResetToDefault extends DataLocationEvent {}

class DataLocationSetCustomPath extends DataLocationEvent {
  const DataLocationSetCustomPath(this.path);

  final String path;
}

class DataLocationClearState extends DataLocationEvent {}
