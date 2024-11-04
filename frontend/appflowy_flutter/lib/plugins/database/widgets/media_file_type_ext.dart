import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';

extension FileTypeDisplay on MediaFileTypePB {
  FlowySvgData get icon => switch (this) {
        MediaFileTypePB.Image => FlowySvgs.image_s,
        MediaFileTypePB.Link => FlowySvgs.ft_link_s,
        MediaFileTypePB.Document => FlowySvgs.icon_document_s,
        MediaFileTypePB.Archive => FlowySvgs.ft_archive_s,
        MediaFileTypePB.Video => FlowySvgs.ft_video_s,
        MediaFileTypePB.Audio => FlowySvgs.ft_audio_s,
        MediaFileTypePB.Text => FlowySvgs.ft_text_s,
        _ => FlowySvgs.icon_document_s,
      };

  Color get color => switch (this) {
        MediaFileTypePB.Image => const Color(0xFF5465A1),
        MediaFileTypePB.Link => const Color(0xFFA35F94),
        MediaFileTypePB.Document => const Color(0xFFBAAC74),
        MediaFileTypePB.Archive => const Color(0xFF40AAB8),
        MediaFileTypePB.Video => const Color(0xFF5465A1),
        MediaFileTypePB.Audio => const Color(0xFF5465A1),
        MediaFileTypePB.Text => const Color(0xFF87B3A8),
        _ => const Color(0xFF87B3A8),
      };
}
