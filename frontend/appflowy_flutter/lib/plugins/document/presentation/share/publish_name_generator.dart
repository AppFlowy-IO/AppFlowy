String replaceInvalidChars(String input) {
  final RegExp invalidCharsRegex = RegExp('[^a-zA-Z0-9-]');
  return input.replaceAll(invalidCharsRegex, '');
}

Future<String> generateNameSpace() async {
  return '';
}

// The backend limits the publish name to a maximum of 120 characters.
// If the combined length of the ID and the name exceeds 120 characters,
// we will truncate the name to ensure the final result is within the limit.
// The name should only contain alphanumeric characters and hyphens.
Future<String> generatePublishName(String id, String name) async {
  if (name.length >= 120 - id.length) {
    name = name.substring(0, 120 - id.length);
  }
  return replaceInvalidChars('$name-$id');
}
