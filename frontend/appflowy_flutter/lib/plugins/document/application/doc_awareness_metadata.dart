// This file is "main.dart"
import 'package:freezed_annotation/freezed_annotation.dart';

part 'doc_awareness_metadata.freezed.dart';
part 'doc_awareness_metadata.g.dart';

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

@freezed
class DocumentAwarenessCollaborator with _$DocumentAwarenessCollaborator {
  const factory DocumentAwarenessCollaborator({
    required String userName,
    required String userAvatar,
  }) = _DocumentAwarenessCollaborator;

  factory DocumentAwarenessCollaborator.fromJson(Map<String, Object?> json) =>
      _$DocumentAwarenessCollaboratorFromJson(json);
}
