import 'dart:math';

import 'package:flowy_infra/uuid.dart';

final _regExp = RegExp(r'[^\w\-\.@:/]');

Future<String> generateNameSpace() async {
  const workspaceName = '';
  final id = uuid().substring(0, 8);
  return '$workspaceName$id'.replaceAll(_regExp, '-');
}

// The backend limits the publish name to a maximum of 50 characters.
// If the combined length of the ID and the name exceeds 50 characters,
// we will truncate the name to ensure the final result is within the limit.
// The name should only contain alphanumeric characters and hyphens.
Future<String> generatePublishName(String id, String name) async {
  final result = '${name.substring(0, min(49 - id.length, name.length))}-$id';
  return result.replaceAll(_regExp, '-');
}
