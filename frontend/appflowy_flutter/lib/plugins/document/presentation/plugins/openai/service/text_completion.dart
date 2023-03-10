import 'package:freezed_annotation/freezed_annotation.dart';
part 'text_completion.freezed.dart';
part 'text_completion.g.dart';

@freezed
class TextCompletionChoice with _$TextCompletionChoice {
  factory TextCompletionChoice({
    required String text,
    required int index,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'finish_reason') String? finishReason,
  }) = _TextCompletionChoice;

  factory TextCompletionChoice.fromJson(Map<String, Object?> json) =>
      _$TextCompletionChoiceFromJson(json);
}

@freezed
class TextCompletionResponse with _$TextCompletionResponse {
  const factory TextCompletionResponse({
    required List<TextCompletionChoice> choices,
  }) = _TextCompletionResponse;

  factory TextCompletionResponse.fromJson(Map<String, Object?> json) =>
      _$TextCompletionResponseFromJson(json);
}
