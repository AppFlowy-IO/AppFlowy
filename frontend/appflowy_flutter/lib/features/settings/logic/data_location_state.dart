import 'package:equatable/equatable.dart';

import '../data/models/user_data_location.dart';

class DataLocationState extends Equatable {
  const DataLocationState({
    required this.userDataLocation,
    required this.didResetToDefault,
  });

  factory DataLocationState.initial() =>
      const DataLocationState(userDataLocation: null, didResetToDefault: false);

  final UserDataLocation? userDataLocation;
  final bool didResetToDefault;

  @override
  List<Object?> get props => [userDataLocation, didResetToDefault];

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
