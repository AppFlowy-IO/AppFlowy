import 'package:equatable/equatable.dart';

class UserDataLocation extends Equatable {
  const UserDataLocation({
    required this.path,
    required this.isCustom,
  });

  final String path;
  final bool isCustom;

  @override
  List<Object?> get props => [path, isCustom];
}
