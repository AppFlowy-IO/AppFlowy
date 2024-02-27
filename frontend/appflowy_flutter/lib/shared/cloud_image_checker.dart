import 'dart:convert';

import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:http/http.dart' as http;

Future<bool> isImageExistOnCloud({
  required String url,
  required UserProfilePB userProfilePB,
}) async {
  final header = <String, String>{};
  final token = userProfilePB.token;
  try {
    final decodedToken = jsonDecode(token);
    header['Authorization'] = 'Bearer ${decodedToken['access_token']}';
    final response = await http.get(Uri.http(url), headers: header);
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}
