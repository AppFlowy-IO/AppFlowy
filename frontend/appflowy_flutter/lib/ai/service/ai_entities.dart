import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';

class AIStreamEventPrefix {
  static const data = 'data:';
  static const error = 'error:';
  static const metadata = 'metadata:';
  static const start = 'start:';
  static const finish = 'finish:';
  static const comment = 'comment:';
  static const aiResponseLimit = 'AI_RESPONSE_LIMIT';
  static const aiImageResponseLimit = 'AI_IMAGE_RESPONSE_LIMIT';
  static const aiMaxRequired = 'AI_MAX_REQUIRED:';
  static const localAINotReady = 'LOCAL_AI_NOT_READY';
  static const localAIDisabled = 'LOCAL_AI_DISABLED';
}

enum AiType {
  cloud,
  local;

  bool get isCloud => this == cloud;
  bool get isLocal => this == local;
}

class PredefinedFormat extends Equatable {
  const PredefinedFormat({
    required this.imageFormat,
    required this.textFormat,
  });

  final ImageFormat imageFormat;
  final TextFormat? textFormat;

  PredefinedFormatPB toPB() {
    return PredefinedFormatPB(
      imageFormat: switch (imageFormat) {
        ImageFormat.text => ResponseImageFormatPB.TextOnly,
        ImageFormat.image => ResponseImageFormatPB.ImageOnly,
        ImageFormat.textAndImage => ResponseImageFormatPB.TextAndImage,
      },
      textFormat: switch (textFormat) {
        TextFormat.paragraph => ResponseTextFormatPB.Paragraph,
        TextFormat.bulletList => ResponseTextFormatPB.BulletedList,
        TextFormat.numberedList => ResponseTextFormatPB.NumberedList,
        TextFormat.table => ResponseTextFormatPB.Table,
        _ => null,
      },
    );
  }

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
  paragraph,
  bulletList,
  numberedList,
  table;

  FlowySvgData get icon {
    return switch (this) {
      TextFormat.paragraph => FlowySvgs.ai_paragraph_s,
      TextFormat.bulletList => FlowySvgs.ai_list_s,
      TextFormat.numberedList => FlowySvgs.ai_number_list_s,
      TextFormat.table => FlowySvgs.ai_table_s,
    };
  }

  String get i18n {
    return switch (this) {
      TextFormat.paragraph => LocaleKeys.chat_changeFormat_text.tr(),
      TextFormat.bulletList => LocaleKeys.chat_changeFormat_bullet.tr(),
      TextFormat.numberedList => LocaleKeys.chat_changeFormat_number.tr(),
      TextFormat.table => LocaleKeys.chat_changeFormat_table.tr(),
    };
  }
}
