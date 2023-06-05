import 'package:freezed_annotation/freezed_annotation.dart';
part 'error.freezed.dart';
part 'error.g.dart';

@freezed
class OpenAIError with _$OpenAIError {
  const factory OpenAIError({
    final String? code,
    required final String message,
  }) = _OpenAIError;

  factory OpenAIError.fromJson(final Map<String, Object?> json) =>
      _$OpenAIErrorFromJson(json);
}
