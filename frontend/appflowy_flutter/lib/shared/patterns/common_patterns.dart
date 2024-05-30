const _trailingZerosPattern = r'^(\d+(?:\.\d*?[1-9](?=0|\b))?)\.?0*$';
final trailingZerosRegex = RegExp(_trailingZerosPattern);

const _hrefPattern =
    r'https?://(?:www\.)?[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(?:/[^\s]*)?';
final hrefRegex = RegExp(_hrefPattern);

/// This pattern allows for both HTTP and HTTPS Scheme
/// It allows for query parameters
/// It only allows the following image extensions: .png, .jpg, .gif, .webm
///
const _imgUrlPattern =
    r'(https?:\/\/)([^\s(["<,>/]*)(\/)[^\s[",><]*(.png|.jpg|.gif|.webm)(\?[^\s[",><]*)?';
final imgUrlRegex = RegExp(_imgUrlPattern);

/// This pattern allows for both HTTP and HTTPS Scheme
/// It allows for query parameters
/// It only allows the following video extensions:
///  .mp4, .mov, .avi, .webm, .flv, .m4v (mpeg), .mpeg, .h264,
///
const _videoUrlPattern =
    r'(https?:\/\/)([^\s(["<,>/]*)(\/)[^\s[",><]*(.mp4|.mov|.avi|.webm|.flv|.m4v|.mpeg|.h264)(\?[^\s[",><]*)?';
final videoUrlRegex = RegExp(_videoUrlPattern);

const _appflowyCloudUrlPattern = r'^(https:\/\/)(.*)(\.appflowy\.cloud\/)(.*)';
final appflowyCloudUrlRegex = RegExp(_appflowyCloudUrlPattern);

const _camelCasePattern = '(?<=[a-z])[A-Z]';
final camelCaseRegex = RegExp(_camelCasePattern);

const _macOSVolumesPattern = '^/Volumes/[^/]+';
final macOSVolumesRegex = RegExp(_macOSVolumesPattern);
