// This file is "main.dart"
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_awareness_metadata.freezed.dart';
part 'document_awareness_metadata.g.dart';

@freezed
class DocumentAwarenessMetadata with _$DocumentAwarenessMetadata {
  const factory DocumentAwarenessMetadata({
    // ignore: invalid_annotation_target
    @JsonKey(name: 'cursor_color') required String cursorColor,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'selection_color') required String selectionColor,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'user_name') required String userName,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'user_avatar') required String userAvatar,
  }) = _DocumentAwarenessMetadata;

  factory DocumentAwarenessMetadata.fromJson(Map<String, Object?> json) =>
      _$DocumentAwarenessMetadataFromJson(json);
}
