import 'package:appflowy/shared/patterns/file_type_patterns.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pbenum.dart';
import 'package:cross_file/cross_file.dart';

enum FileType {
  other,
  image,
  link,
  document,
  archive,
  video,
  audio,
  text;
}

extension TypeRecognizer on XFile {
  FileType get fileType {
    // Prefer mime over using regexp as it is more reliable.
    // Refer to Microsoft Documentation for common mime types: https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types
    if (mimeType?.isNotEmpty == true) {
      if (mimeType!.contains('image')) {
        return FileType.image;
      }
      if (mimeType!.contains('video')) {
        return FileType.video;
      }
      if (mimeType!.contains('audio')) {
        return FileType.audio;
      }
      if (mimeType!.contains('text')) {
        return FileType.text;
      }
      if (mimeType!.contains('application')) {
        if (mimeType!.contains('pdf') ||
            mimeType!.contains('doc') ||
            mimeType!.contains('docx')) {
          return FileType.document;
        }
        if (mimeType!.contains('zip') ||
            mimeType!.contains('tar') ||
            mimeType!.contains('gz') ||
            mimeType!.contains('7z') ||
            // archive is used in eg. Java archives (jar)
            mimeType!.contains('archive') ||
            mimeType!.contains('rar')) {
          return FileType.archive;
        }
        if (mimeType!.contains('rtf')) {
          return FileType.text;
        }
      }

      return FileType.other;
    }

    // Check if the file is an image
    if (imgExtensionRegex.hasMatch(path)) {
      return FileType.image;
    }

    // Check if the file is a video
    if (videoExtensionRegex.hasMatch(path)) {
      return FileType.video;
    }

    // Check if the file is an audio
    if (audioExtensionRegex.hasMatch(path)) {
      return FileType.audio;
    }

    // Check if the file is a document
    if (documentExtensionRegex.hasMatch(path)) {
      return FileType.document;
    }

    // Check if the file is an archive
    if (archiveExtensionRegex.hasMatch(path)) {
      return FileType.archive;
    }

    // Check if the file is a text
    if (textExtensionRegex.hasMatch(path)) {
      return FileType.text;
    }

    return FileType.other;
  }
}

extension ToMediaFileTypePB on FileType {
  MediaFileTypePB toMediaFileTypePB() {
    switch (this) {
      case FileType.image:
        return MediaFileTypePB.Image;
      case FileType.video:
        return MediaFileTypePB.Video;
      case FileType.audio:
        return MediaFileTypePB.Audio;
      case FileType.document:
        return MediaFileTypePB.Document;
      case FileType.archive:
        return MediaFileTypePB.Archive;
      case FileType.text:
        return MediaFileTypePB.Text;
      default:
        return MediaFileTypePB.Other;
    }
  }
}
