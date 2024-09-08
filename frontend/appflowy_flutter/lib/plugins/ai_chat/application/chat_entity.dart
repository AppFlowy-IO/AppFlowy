import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as path;

part 'chat_entity.g.dart';
part 'chat_entity.freezed.dart';

const sendMessageErrorKey = "sendMessageError";
const systemUserId = "system";
const aiResponseUserId = "0";

/// `messageRefSourceJsonStringKey` is the key used for metadata that contains the reference source of a message.
/// Each message may include this information.
/// - When used in a sent message, it indicates that the message includes an attachment.
/// - When used in a received message, it indicates the AI reference sources used to answer a question.
const messageRefSourceJsonStringKey = "ref_source_json_string";
const messageChatFileListKey = "chat_files";
const messageQuestionIdKey = "question_id";

@JsonSerializable()
class ChatMessageRefSource {
  ChatMessageRefSource({
    required this.id,
    required this.name,
    required this.source,
  });

  factory ChatMessageRefSource.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageRefSourceFromJson(json);

  final String id;
  final String name;
  final String source;

  Map<String, dynamic> toJson() => _$ChatMessageRefSourceToJson(this);
}

@freezed
class StreamingState with _$StreamingState {
  const factory StreamingState.streaming() = _Streaming;
  const factory StreamingState.done({FlowyError? error}) = _StreamDone;
}

@freezed
class SendMessageState with _$SendMessageState {
  const factory SendMessageState.sending() = _Sending;
  const factory SendMessageState.done({FlowyError? error}) = _SendDone;
}

class ChatFile extends Equatable {
  const ChatFile({
    required this.filePath,
    required this.fileName,
    required this.fileType,
  });

  static ChatFile? fromFilePath(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return null;
    }

    final fileName = path.basename(filePath);
    final extension = path.extension(filePath).toLowerCase();

    ChatMessageMetaTypePB fileType;
    switch (extension) {
      case '.pdf':
        fileType = ChatMessageMetaTypePB.PDF;
        break;
      case '.txt':
        fileType = ChatMessageMetaTypePB.Txt;
        break;
      case '.md':
        fileType = ChatMessageMetaTypePB.Markdown;
        break;
      default:
        fileType = ChatMessageMetaTypePB.UnknownMetaType;
    }

    return ChatFile(
      filePath: filePath,
      fileName: fileName,
      fileType: fileType,
    );
  }

  final String filePath;
  final String fileName;
  final ChatMessageMetaTypePB fileType;

  @override
  List<Object?> get props => [filePath];
}

extension ChatFileTypeExtension on ChatMessageMetaTypePB {
  Widget get icon {
    switch (this) {
      case ChatMessageMetaTypePB.PDF:
        return const FlowySvg(
          FlowySvgs.file_pdf_s,
          color: Color(0xff00BCF0),
        );
      case ChatMessageMetaTypePB.Txt:
        return const FlowySvg(
          FlowySvgs.file_txt_s,
          color: Color(0xff00BCF0),
        );
      case ChatMessageMetaTypePB.Markdown:
        return const FlowySvg(
          FlowySvgs.file_md_s,
          color: Color(0xff00BCF0),
        );
      default:
        return const FlowySvg(FlowySvgs.file_unknown_s);
    }
  }
}

typedef ChatInputFileMetadata = Map<String, ChatFile>;

@freezed
class ChatLoadingState with _$ChatLoadingState {
  const factory ChatLoadingState.loading() = _Loading;
  const factory ChatLoadingState.finish({FlowyError? error}) = _Finish;
}

extension ChatLoadingStateExtension on ChatLoadingState {
  bool get isLoading => this is _Loading;
  bool get isFinish => this is _Finish;
}

enum OnetimeShotType {
  unknown,
  sendingMessage,
  relatedQuestion,
  invalidSendMesssage,
}

const onetimeShotType = "OnetimeShotType";

extension OnetimeMessageTypeExtension on OnetimeShotType {
  static OnetimeShotType fromString(String value) {
    switch (value) {
      case 'OnetimeShotType.sendingMessage':
        return OnetimeShotType.sendingMessage;
      case 'OnetimeShotType.relatedQuestion':
        return OnetimeShotType.relatedQuestion;
      case 'OnetimeShotType.invalidSendMesssage':
        return OnetimeShotType.invalidSendMesssage;
      default:
        Log.error('Unknown OnetimeShotType: $value');
        return OnetimeShotType.unknown;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      onetimeShotType: toString(),
    };
  }
}

OnetimeShotType? onetimeMessageTypeFromMeta(Map<String, dynamic>? metadata) {
  if (metadata == null) {
    return null;
  }

  for (final entry in metadata.entries) {
    if (entry.key == onetimeShotType) {
      return OnetimeMessageTypeExtension.fromString(entry.value as String);
    }
  }
  return null;
}
