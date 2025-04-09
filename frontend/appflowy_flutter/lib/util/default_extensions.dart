/// List of default file extensions used for images.
///
/// This is used to make sure that only images that are allowed are picked/uploaded. The extensions
/// should be supported by Flutter, to avoid causing issues.
///
/// See [Image-class documentation](https://api.flutter.dev/flutter/widgets/Image-class.html)
///
const List<String> defaultImageExtensions = [
  'jpg',
  'png',
  'jpeg',
  'gif',
  'webp',
  'bmp',
];

bool isNotImageUrl(String url) {
  final nonImageSuffixRegex = RegExp(
    r'\.(io|html|php|json|txt|js|css|xml|md|log)(\?.*)?(#.*)?$',
    caseSensitive: false,
  );
  return nonImageSuffixRegex.hasMatch(url);
}
