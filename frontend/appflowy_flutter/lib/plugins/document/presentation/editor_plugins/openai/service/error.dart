import 'package:freezed_annotation/freezed_annotation.dart';
part 'error.freezed.dart';
part 'error.g.dart';

@freezed
class AIError with _$AIError {
  const factory AIError({
    String? code,
    required String message,
  }) = _AIError;

  factory AIError.fromJson(Map<String, Object?> json) =>
      _$AIErrorFromJson(json);
}
