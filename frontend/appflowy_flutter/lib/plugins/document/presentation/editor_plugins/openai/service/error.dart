import 'package:freezed_annotation/freezed_annotation.dart';

part 'error.freezed.dart';
part 'error.g.dart';

@freezed
class AIError with _$AIError {
  const factory AIError({
    required String message,
    @Default(AIErrorCode.other) AIErrorCode code,
  }) = _AIError;

  factory AIError.fromJson(Map<String, Object?> json) =>
      _$AIErrorFromJson(json);
}

enum AIErrorCode {
  @JsonValue('AIResponseLimitExceeded')
  aiResponseLimitExceeded,
  @JsonValue('Other')
  other,
}

extension AIErrorExtension on AIError {
  bool get isLimitedExceeded => code == AIErrorCode.aiResponseLimitExceeded;
}
