import '../data/models/user_data_location.dart';

class DataLocationState {
  const DataLocationState({
    required this.userDataLocation,
  });

  factory DataLocationState.initial() =>
      const DataLocationState(userDataLocation: null);

  final UserDataLocation? userDataLocation;
}
