import 'package:flutter/foundation.dart';

import 'package:appflowy/user/application/github/github_service.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'version_checker_bloc.freezed.dart';

class VersionCheckerBloc
    extends Bloc<VersionCheckerEvent, VersionCheckerState> {
  VersionCheckerBloc() : super(const VersionCheckerState()) {
    _gitHubService = GitHubService();

    on<VersionCheckerEvent>((event, emit) async {
      await event.when(
        checkLatestRelease: () async {
          final releaseInfo = await _gitHubService.checkLatestGitHubRelease();
          final currentInfo = await PackageInfo.fromPlatform();

          if (releaseInfo == null) {
            // We "fail" silently here because we don't want to bother users without network connection
            return emit(
              state.copyWith(
                appName: currentInfo.appName,
                currentVersion: currentInfo.version,
                isLoading: false,
                isUpdateAvailable: false,
              ),
            );
          } else {
            emit(
              state.copyWith(
                appName: currentInfo.appName,
                currentVersion: currentInfo.version,
                latestVersion: releaseInfo.tagName,
                isUpdateAvailable: currentInfo.version != releaseInfo.tagName,
                isLoading: false,
                changelog: releaseInfo.changelog,
                downloadLink: releaseInfo.htmlUrl,
              ),
            );
          }
        },
      );
    });
  }

  late final IGitHubService _gitHubService;

  @override
  Future<void> close() async {
    _gitHubService.dispose();
    return super.close();
  }
}

@freezed
class VersionCheckerEvent with _$VersionCheckerEvent {
  const factory VersionCheckerEvent.checkLatestRelease() = _CheckLatestRelease;
}

@freezed
class VersionCheckerState with _$VersionCheckerState {
  const factory VersionCheckerState({
    @Default(null) String? appName,
    @Default(null) String? currentVersion,
    @Default(null) String? latestVersion,
    @Default(false) bool isUpdateAvailable,
    @Default(true) bool isLoading,
    @Default(null) String? changelog,
    @Default(null) String? downloadLink,
  }) = _VersionCheckerState;
}
