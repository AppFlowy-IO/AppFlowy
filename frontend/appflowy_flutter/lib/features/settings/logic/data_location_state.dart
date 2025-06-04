import '../data/models/user_data_location.dart';

class DataLocationState {
  const DataLocationState({
    required this.userDataLocation,
    required this.didResetToDefault,
  });

  factory DataLocationState.initial() =>
      const DataLocationState(userDataLocation: null, didResetToDefault: false);

  final UserDataLocation? userDataLocation;
  final bool didResetToDefault;

  DataLocationState copyWith({
    UserDataLocation? userDataLocation,
    bool? didResetToDefault,
  }) {
    return DataLocationState(
      userDataLocation: userDataLocation ?? this.userDataLocation,
      didResetToDefault: didResetToDefault ?? this.didResetToDefault,
    );
  }
}
