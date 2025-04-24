import 'dart:convert';

import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:http/http.dart' as http;

enum InviteCodeEndpoint {
  getInviteCode,
  deleteInviteCode,
  generateInviteCode;

  String get path {
    switch (this) {
      case InviteCodeEndpoint.getInviteCode:
      case InviteCodeEndpoint.deleteInviteCode:
      case InviteCodeEndpoint.generateInviteCode:
        return '/api/workspace/{workspaceId}/invite-code';
    }
  }

  String get method {
    switch (this) {
      case InviteCodeEndpoint.getInviteCode:
        return 'GET';
      case InviteCodeEndpoint.deleteInviteCode:
        return 'DELETE';
      case InviteCodeEndpoint.generateInviteCode:
        return 'POST';
    }
  }

  Uri uri(String baseUrl, String workspaceId) =>
      Uri.parse(path.replaceAll('{workspaceId}', workspaceId)).replace(
        scheme: Uri.parse(baseUrl).scheme,
        host: Uri.parse(baseUrl).host,
        port: Uri.parse(baseUrl).port,
      );
}

class MemberHttpService {
  MemberHttpService({
    required this.baseUrl,
    required this.authToken,
  });

  final String baseUrl;
  final String authToken;

  final http.Client client = http.Client();

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  /// Gets the invite code for a workspace
  Future<FlowyResult<String, FlowyError>> getInviteCode({
    required String workspaceId,
  }) async {
    final result = await _makeRequest(
      endpoint: InviteCodeEndpoint.getInviteCode,
      workspaceId: workspaceId,
      errorMessage: 'Failed to get invite code',
    );

    try {
      return result.fold(
        (data) => FlowyResult.success(data['code'] as String),
        (error) => FlowyResult.failure(error),
      );
    } catch (e) {
      return FlowyResult.failure(
        FlowyError(msg: 'Failed to get invite code: $e'),
      );
    }
  }

  /// Deletes the invite code for a workspace
  Future<FlowyResult<bool, FlowyError>> deleteInviteCode({
    required String workspaceId,
  }) async {
    final result = await _makeRequest(
      endpoint: InviteCodeEndpoint.deleteInviteCode,
      workspaceId: workspaceId,
      errorMessage: 'Failed to delete invite code',
    );

    return result.fold(
      (data) => FlowyResult.success(true),
      (error) => FlowyResult.failure(error),
    );
  }

  /// Generates a new invite code for a workspace
  ///
  /// [workspaceId] - The ID of the workspace
  Future<FlowyResult<String, FlowyError>> generateInviteCode({
    required String workspaceId,
    int? validityPeriodHours,
  }) async {
    final result = await _makeRequest(
      endpoint: InviteCodeEndpoint.generateInviteCode,
      workspaceId: workspaceId,
      errorMessage: 'Failed to generate invite code',
      body: {
        'validity_period_hours': validityPeriodHours,
      },
    );

    try {
      return result.fold(
        (data) => FlowyResult.success(data['data']['code'].toString()),
        (error) => FlowyResult.failure(error),
      );
    } catch (e) {
      return FlowyResult.failure(
        FlowyError(msg: 'Failed to generate invite code: $e'),
      );
    }
  }

  /// Makes a request to the specified endpoint
  Future<FlowyResult<dynamic, FlowyError>> _makeRequest({
    required InviteCodeEndpoint endpoint,
    required String workspaceId,
    Map<String, dynamic>? body,
    String errorMessage = 'Request failed',
  }) async {
    try {
      final uri = endpoint.uri(baseUrl, workspaceId);
      http.Response response;

      switch (endpoint.method) {
        case 'GET':
          response = await client.get(
            uri,
            headers: headers,
          );
          break;
        case 'DELETE':
          response = await client.delete(
            uri,
            headers: headers,
          );
          break;
        case 'POST':
          response = await client.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        default:
          return FlowyResult.failure(
            FlowyError(msg: 'Invalid request method: ${endpoint.method}'),
          );
      }

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          return FlowyResult.success(jsonDecode(response.body));
        }
        return FlowyResult.success(true);
      } else {
        final errorBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};

        Log.info(
          '${endpoint.name} request failed: ${response.statusCode}, $errorBody',
        );

        return FlowyResult.failure(
          FlowyError(
            msg: errorBody['msg'] ?? errorMessage,
          ),
        );
      }
    } catch (e) {
      Log.error('${endpoint.name} request failed: error: $e');

      return FlowyResult.failure(
        FlowyError(msg: 'Network error: ${e.toString()}'),
      );
    }
  }
}
