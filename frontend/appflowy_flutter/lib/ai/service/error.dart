import 'package:freezed_annotation/freezed_annotation.dart';

part 'error.freezed.dart';
part 'error.g.dart';

@freezed
class AIError with _$AIError {
  const factory AIError({
    required String message,
    required AIErrorCode code,
  }) = _AIError;

  factory AIError.fromJson(Map<String, Object?> json) =>
      _$AIErrorFromJson(json);
}

enum AIErrorCode {
  @JsonValue('AIResponseLimitExceeded')
  aiResponseLimitExceeded,
  @JsonValue('AIImageResponseLimitExceeded')
  aiImageResponseLimitExceeded,
  @JsonValue('Other')
  other,
}

extension AIErrorExtension on AIError {
  bool get isLimitExceeded => code == AIErrorCode.aiResponseLimitExceeded;
}
