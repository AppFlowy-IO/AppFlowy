import 'dart:convert';

import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_action_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:nanoid/nanoid.dart';

import 'chat_file_bloc.dart';

List<ChatFile> fileListFromMessageMetadata(
  Map<String, dynamic>? map,
) {
  final List<ChatFile> metadata = [];
  if (map != null) {
    for (final entry in map.entries) {
      if (entry.value is ChatFile) {
        metadata.add(entry.value);
      }
    }
  }

  return metadata;
}

List<ChatFile> chatFilesFromMetadataString(String? s) {
  if (s == null || s.isEmpty || s == "null") {
    return [];
  }

  final metadataJson = jsonDecode(s);
  if (metadataJson is Map<String, dynamic>) {
    return _parseChatFile(metadataJson);
  } else if (metadataJson is List) {
    return metadataJson
        .map((e) => e as Map<String, dynamic>)
        .map(chatFileFromMap)
        .where((file) => file != null)
        .cast<ChatFile>()
        .toList();
  } else {
    Log.error("Invalid metadata: $metadataJson");
    return [];
  }
}

List<ChatFile> _parseChatFile(Map<String, dynamic> map) {
  final file = chatFileFromMap(map);
  return file != null ? [file] : [];
}

ChatFile? chatFileFromMap(Map<String, dynamic>? map) {
  if (map == null) return null;

  final filePath = map['source'] as String?;
  final fileName = map['name'] as String?;

  if (filePath == null || fileName == null) {
    return null;
  }
  return ChatFile.fromFilePath(filePath);
}

List<ChatMessageRefSource> messageRefSourceFromString(String? s) {
  if (s == null || s.isEmpty || s == "null") {
    return [];
  }

  final List<ChatMessageRefSource> metadata = [];
  try {
    final metadataJson = jsonDecode(s);
    if (metadataJson == null) {
      Log.warn("metadata is null");
      return [];
    }

    if (metadataJson is Map<String, dynamic>) {
      if (metadataJson.isNotEmpty) {
        metadata.add(ChatMessageRefSource.fromJson(metadataJson));
      }
    } else if (metadataJson is List) {
      metadata.addAll(
        metadataJson.map(
          (e) => ChatMessageRefSource.fromJson(e as Map<String, dynamic>),
        ),
      );
    } else {
      Log.error("Invalid metadata: $metadataJson");
    }
  } catch (e) {
    Log.error("Failed to parse metadata: $e");
  }

  return metadata;
}

Future<List<ChatMessageMetaPB>> metadataPBFromMetadata(
  Map<String, dynamic>? map,
) async {
  final List<ChatMessageMetaPB> metadata = [];
  if (map != null) {
    for (final entry in map.entries) {
      if (entry.value is ViewActionPage) {
        if (entry.value.page is ViewPB) {
          final view = entry.value.page as ViewPB;
          if (view.layout.isDocumentView) {
            final payload = OpenDocumentPayloadPB(documentId: view.id);
            final result = await DocumentEventGetDocumentText(payload).send();
            result.fold((pb) {
              metadata.add(
                ChatMessageMetaPB(
                  id: view.id,
                  name: view.name,
                  data: pb.text,
                  dataType: ChatMessageMetaTypePB.Txt,
                  source: "appflowy",
                ),
              );
            }, (err) {
              Log.error('Failed to get document text: $err');
            });
          }
        }
      } else if (entry.value is ChatFile) {
        metadata.add(
          ChatMessageMetaPB(
            id: nanoid(8),
            name: entry.value.fileName,
            data: entry.value.filePath,
            dataType: entry.value.fileType,
            source: entry.value.filePath,
          ),
        );
      }
    }
  }

  return metadata;
}
