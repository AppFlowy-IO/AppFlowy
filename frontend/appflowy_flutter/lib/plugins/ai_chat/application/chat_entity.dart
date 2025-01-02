import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
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

    ContextLoaderTypePB fileType;
    switch (extension) {
      case '.pdf':
        fileType = ContextLoaderTypePB.PDF;
        break;
      case '.txt':
        fileType = ContextLoaderTypePB.Txt;
        break;
      case '.md':
        fileType = ContextLoaderTypePB.Markdown;
        break;
      default:
        fileType = ContextLoaderTypePB.UnknownLoaderType;
    }

    return ChatFile(
      filePath: filePath,
      fileName: fileName,
      fileType: fileType,
    );
  }

  final String filePath;
  final String fileName;
  final ContextLoaderTypePB fileType;

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

enum LoadChatMessageStatus {
  loading,
  loadingRemote,
  ready,
}

class PredefinedFormat extends Equatable {
  const PredefinedFormat({
    required this.imageFormat,
    required this.textFormat,
  });

  const PredefinedFormat.auto()
      : imageFormat = ImageFormat.text,
        textFormat = TextFormat.auto;

  final ImageFormat imageFormat;
  final TextFormat? textFormat;

  @override
  List<Object?> get props => [imageFormat, textFormat];
}

enum ImageFormat {
  text,
  image,
  textAndImage;

  bool get hasText => this == text || this == textAndImage;

  FlowySvgData get icon {
    return switch (this) {
      ImageFormat.text => FlowySvgs.ai_text_s,
      ImageFormat.image => FlowySvgs.ai_image_s,
      ImageFormat.textAndImage => FlowySvgs.ai_text_image_s,
    };
  }

  String get i18n {
    return switch (this) {
      ImageFormat.text => LocaleKeys.chat_changeFormat_textOnly.tr(),
      ImageFormat.image => LocaleKeys.chat_changeFormat_imageOnly.tr(),
      ImageFormat.textAndImage =>
        LocaleKeys.chat_changeFormat_textAndImage.tr(),
    };
  }
}

enum TextFormat {
  auto,
  bulletList,
  numberedList,
  table;

  FlowySvgData get icon {
    return switch (this) {
      TextFormat.auto => FlowySvgs.ai_paragraph_s,
      TextFormat.bulletList => FlowySvgs.ai_list_s,
      TextFormat.numberedList => FlowySvgs.ai_number_list_s,
      TextFormat.table => FlowySvgs.ai_table_s,
    };
  }

  String get i18n {
    return switch (this) {
      TextFormat.auto => LocaleKeys.chat_changeFormat_text.tr(),
      TextFormat.bulletList => LocaleKeys.chat_changeFormat_bullet.tr(),
      TextFormat.numberedList => LocaleKeys.chat_changeFormat_number.tr(),
      TextFormat.table => LocaleKeys.chat_changeFormat_table.tr(),
    };
  }
}
