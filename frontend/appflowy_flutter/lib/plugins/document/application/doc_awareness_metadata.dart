// This file is "main.dart"
import 'package:freezed_annotation/freezed_annotation.dart';

part 'doc_awareness_metadata.freezed.dart';
part 'doc_awareness_metadata.g.dart';

@freezed
class DocAwarenessMetadata with _$DocAwarenessMetadata {
  const factory DocAwarenessMetadata({
    required String cursorColor,
    required String selectionColor,
    required String userName,
    required String userAvatar,
  }) = _DocAwarenessMetadata;

  factory DocAwarenessMetadata.fromJson(Map<String, Object?> json) =>
      _$DocAwarenessMetadataFromJson(json);
}
