import 'dart:io';

import 'package:appflowy_backend/protobuf/flowy-ai/entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as path;

part 'chat_entity.g.dart';
part 'chat_entity.freezed.dart';

const errorMessageTextKey = "errorMessageText";
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

@JsonSerializable()
class AIChatProgress {
  AIChatProgress({
    required this.step,
  });

  factory AIChatProgress.fromJson(Map<String, dynamic> json) =>
      _$AIChatProgressFromJson(json);

  final String step;

  Map<String, dynamic> toJson() => _$AIChatProgressToJson(this);
}

enum PromptResponseState {
  ready,
  sendingQuestion,
  awaitingAnswer,
  streamingAnswer,
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

typedef ChatFileMap = Map<String, ChatFile>;
typedef ChatMentionedPageMap = Map<String, ViewPB>;

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
  sendingMessage,
  relatedQuestion,
  error,
}

const onetimeShotType = "OnetimeShotType";

OnetimeShotType? onetimeMessageTypeFromMeta(Map<String, dynamic>? metadata) {
  return metadata?[onetimeShotType];
}
