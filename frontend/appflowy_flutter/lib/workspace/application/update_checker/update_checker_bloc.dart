import 'package:flutter/foundation.dart';

import 'package:appflowy/user/application/github/github_service.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'update_checker_bloc.freezed.dart';

class VersionCheckerBloc
    extends Bloc<VersionCheckerEvent, VersionCheckerState> {
  VersionCheckerBloc() : super(const VersionCheckerState.initial()) {
    _gitHubService = GitHubService();

    on<VersionCheckerEvent>((event, emit) async {
      await event.when(
        checkLatestRelease: () async {
          final releaseInfo = await _gitHubService.checkLatestGitHubRelease();
          final currentInfo = await PackageInfo.fromPlatform();

          if (releaseInfo == null) {
            // Fail silently
            return emit(const VersionCheckerState.upToDate());
          } else {
            final currentVersion = currentInfo.version;
            if (currentVersion != releaseInfo.tagName) {
              emit(
                VersionCheckerState.updateAvailable(
                  version: releaseInfo.tagName,
                ),
              );
            } else {
              emit(const VersionCheckerState.upToDate());
            }
          }
        },
      );
    });
  }

  late final IGitHubService _gitHubService;
}

@freezed
class VersionCheckerEvent with _$VersionCheckerEvent {
  const factory VersionCheckerEvent.checkLatestRelease() = _CheckLatestRelease;
}

@freezed
class VersionCheckerState with _$VersionCheckerState {
  const factory VersionCheckerState.initial() = _Initial;
  const factory VersionCheckerState.fetchingVersions() = _FetchingVersions;
  const factory VersionCheckerState.upToDate() = _UpToDate;
  const factory VersionCheckerState.updateAvailable({required String version}) =
      _UpdateAvailable;
}
