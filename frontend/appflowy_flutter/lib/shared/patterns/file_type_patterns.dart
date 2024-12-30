/// This pattern matches a file extension that is an image.
///
const _imgExtensionPattern = r'\.(gif|jpe?g|tiff?|png|webp|bmp)$';
final imgExtensionRegex = RegExp(_imgExtensionPattern);

/// This pattern matches a file extension that is a video.
///
const _videoExtensionPattern = r'\.(mp4|mov|avi|webm|flv|m4v|mpeg|h264)$';
final videoExtensionRegex = RegExp(_videoExtensionPattern);

/// This pattern matches a file extension that is an audio.
///
const _audioExtensionPattern = r'\.(mp3|wav|ogg|flac|aac|wma|alac|aiff)$';
final audioExtensionRegex = RegExp(_audioExtensionPattern);

/// This pattern matches a file extension that is a document.
///
const _documentExtensionPattern = r'\.(pdf|doc|docx)$';
final documentExtensionRegex = RegExp(_documentExtensionPattern);

/// This pattern matches a file extension that is an archive.
///
const _archiveExtensionPattern = r'\.(zip|tar|gz|7z|rar)$';
final archiveExtensionRegex = RegExp(_archiveExtensionPattern);

/// This pattern matches a file extension that is a text.
///
const _textExtensionPattern = r'\.(txt|md|html|css|js|json|xml|csv)$';
final textExtensionRegex = RegExp(_textExtensionPattern);
