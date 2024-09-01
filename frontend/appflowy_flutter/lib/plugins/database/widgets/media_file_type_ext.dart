import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';

extension ToIcon on MediaFileTypePB {
  FlowySvgData get icon => switch (this) {
        MediaFileTypePB.Image => FlowySvgs.image_s,
        MediaFileTypePB.Link => FlowySvgs.ft_link_s,
        MediaFileTypePB.Document => FlowySvgs.document_s,
        MediaFileTypePB.Archive => FlowySvgs.ft_archive_s,
        MediaFileTypePB.Video => FlowySvgs.ft_video_s,
        MediaFileTypePB.Audio => FlowySvgs.ft_audio_s,
        MediaFileTypePB.Text => FlowySvgs.ft_text_s,
        _ => FlowySvgs.document_s,
      };
}
