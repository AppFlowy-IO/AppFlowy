// ignore_for_file: invalid_annotation_target

import 'dart:convert';

import 'package:appflowy_backend/log.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;

part 'github_service.freezed.dart';
part 'github_service.g.dart';

abstract class IGitHubService {
  /// Checks for the latest release on GitHub.
  ///
  /// Returns [GitHubReleaseInfo] if the request is successful, otherwise returns null.
  Future<GitHubReleaseInfo?> checkLatestGitHubRelease();

  /// Disposes of any resources used by the service.
  ///
  void dispose();
}

@freezed
class GitHubReleaseInfo with _$GitHubReleaseInfo {
  const GitHubReleaseInfo._();

  const factory GitHubReleaseInfo({
    @JsonKey(name: 'tag_name') required String tagName,
    required String name,
    @JsonKey(name: 'body') required String changelog,
    @JsonKey(name: 'html_url') required String htmlUrl,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'published_at') required String publishedAt,
  }) = _GitHubReleaseInfo;

  factory GitHubReleaseInfo.fromJson(Map<String, dynamic> json) =>
      _$GitHubReleaseInfoFromJson(json);
}

class GitHubService implements IGitHubService {
  GitHubService();

  static const String _gitHubVersionHeader = 'X-GitHub-Api-Version';
  static const String _gitHubVersion = '2022-11-28';

  static const String _baseUrl = 'https://api.github.com';
  static const String _repo = '/repos/AppFlowy-IO/AppFlowy';

  static const String _latestReleaseEndpoint = '/releases/latest';

  final http.Client _client = http.Client();
  Uri _uri = Uri.parse(_baseUrl);

  @override
  Future<GitHubReleaseInfo?> checkLatestGitHubRelease() async {
    _uri = _uri.replace(path: '$_repo$_latestReleaseEndpoint');
    try {
      final response = await _client.get(
        _uri,
        headers: {
          _gitHubVersionHeader: _gitHubVersion,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        return GitHubReleaseInfo.fromJson(body);
      } else if (response.statusCode == 403) {
        // For unauthenticated usage, the rate limit is 60 requests per hour.
        //
        // https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28
        Log.warn(
          'checkLatestGitHubRelease failed: GitHub API rate limit exceeded',
        );
      }
    } on http.ClientException catch (e, s) {
      Log.error(
        'checkLatestGitHubRelease failed: ${e.message}\n$s',
      );
    } on TypeError catch (e) {
      Log.error(
        'checkLatestGitHubRelease failed mapping GitHubReleaseInfo\n${e.stackTrace}',
      );
    }

    return null;
  }

  @override
  void dispose() {
    _client.close();
  }
}
