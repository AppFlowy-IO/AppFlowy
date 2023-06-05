import 'package:freezed_annotation/freezed_annotation.dart';
part 'text_edit.freezed.dart';
part 'text_edit.g.dart';

@freezed
class TextEditChoice with _$TextEditChoice {
  factory TextEditChoice({
    required final String text,
    required final int index,
  }) = _TextEditChoice;

  factory TextEditChoice.fromJson(final Map<String, Object?> json) =>
      _$TextEditChoiceFromJson(json);
}

@freezed
class TextEditResponse with _$TextEditResponse {
  const factory TextEditResponse({
    required final List<TextEditChoice> choices,
  }) = _TextEditResponse;

  factory TextEditResponse.fromJson(final Map<String, Object?> json) =>
      _$TextEditResponseFromJson(json);
}
