import 'dart:convert';

import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:http/http.dart' as http;

enum PasswordEndpoint {
  changePassword,
  forgotPassword,
  setupPassword,
  checkHasPassword;

  String get path {
    switch (this) {
      case PasswordEndpoint.changePassword:
        return '/gotrue/user/change-password';
      case PasswordEndpoint.forgotPassword:
        return '/gotrue/user/recover';
      case PasswordEndpoint.setupPassword:
        return '/gotrue/user/change-password';
      case PasswordEndpoint.checkHasPassword:
        return '/gotrue/user/auth-info';
    }
  }

  String get method {
    switch (this) {
      case PasswordEndpoint.changePassword:
      case PasswordEndpoint.setupPassword:
      case PasswordEndpoint.forgotPassword:
        return 'POST';
      case PasswordEndpoint.checkHasPassword:
        return 'GET';
    }
  }

  Uri uri(String baseUrl) => Uri.parse('$baseUrl$path');
}

class PasswordHttpService {
  PasswordHttpService({
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

  /// Changes the user's password
  ///
  /// [currentPassword] - The user's current password
  /// [newPassword] - The new password to set
  Future<FlowyResult<bool, FlowyError>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _makeRequest(
      endpoint: PasswordEndpoint.changePassword,
      body: {
        'current_password': currentPassword,
        'password': newPassword,
      },
      errorMessage: 'Failed to change password',
    );

    return result.fold(
      (data) => FlowyResult.success(true),
      (error) => FlowyResult.failure(error),
    );
  }

  /// Sends a password reset email to the user
  ///
  /// [email] - The email address of the user
  Future<FlowyResult<bool, FlowyError>> forgotPassword({
    required String email,
  }) async {
    final result = await _makeRequest(
      endpoint: PasswordEndpoint.forgotPassword,
      body: {'email': email},
      errorMessage: 'Failed to send password reset email',
    );

    return result.fold(
      (data) => FlowyResult.success(true),
      (error) => FlowyResult.failure(error),
    );
  }

  /// Sets up a password for a user that doesn't have one
  ///
  /// [newPassword] - The new password to set
  Future<FlowyResult<bool, FlowyError>> setupPassword({
    required String newPassword,
  }) async {
    final result = await _makeRequest(
      endpoint: PasswordEndpoint.setupPassword,
      body: {'password': newPassword},
      errorMessage: 'Failed to setup password',
    );

    return result.fold(
      (data) => FlowyResult.success(true),
      (error) => FlowyResult.failure(error),
    );
  }

  /// Checks if the user has a password set
  Future<FlowyResult<bool, FlowyError>> checkHasPassword() async {
    final result = await _makeRequest(
      endpoint: PasswordEndpoint.checkHasPassword,
      errorMessage: 'Failed to check password status',
    );

    return result.fold(
      (data) => FlowyResult.success(data['has_password'] ?? false),
      (error) => FlowyResult.failure(error),
    );
  }

  /// Makes a request to the specified endpoint with the given body
  Future<FlowyResult<dynamic, FlowyError>> _makeRequest({
    required PasswordEndpoint endpoint,
    Map<String, dynamic>? body,
    String errorMessage = 'Request failed',
  }) async {
    try {
      final uri = endpoint.uri(baseUrl);
      http.Response response;

      if (endpoint.method == 'POST') {
        response = await client.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      } else if (endpoint.method == 'GET') {
        response = await client.get(
          uri,
          headers: headers,
        );
      } else {
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
          '${endpoint.name} request failed: ${response.statusCode}, $errorBody ',
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
