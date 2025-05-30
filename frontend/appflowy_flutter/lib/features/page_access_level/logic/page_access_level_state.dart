import 'package:appflowy/features/share_tab/data/models/share_access_level.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

class PageAccessLevelState {
  factory PageAccessLevelState.initial(ViewPB view) => PageAccessLevelState(
        view: view,
        isLocked: false,
        lockCounter: 0,
        accessLevel: ShareAccessLevel
            .readAndWrite, // replace it with readOnly if we support offline.
      );

  const PageAccessLevelState({
    required this.view,
    required this.isLocked,
    required this.lockCounter,
    required this.accessLevel,
    this.isLoadingLockStatus = true,
  });

  final ViewPB view;
  final bool isLocked;
  final int lockCounter;
  final bool isLoadingLockStatus;
  final ShareAccessLevel accessLevel;

  bool get isEditable => accessLevel != ShareAccessLevel.readOnly && !isLocked;

  bool get isReadOnly => accessLevel == ShareAccessLevel.readOnly;

  PageAccessLevelState copyWith({
    ViewPB? view,
    bool? isLocked,
    int? lockCounter,
    bool? isLoadingLockStatus,
    ShareAccessLevel? accessLevel,
  }) {
    return PageAccessLevelState(
      view: view ?? this.view,
      isLocked: isLocked ?? this.isLocked,
      lockCounter: lockCounter ?? this.lockCounter,
      isLoadingLockStatus: isLoadingLockStatus ?? this.isLoadingLockStatus,
      accessLevel: accessLevel ?? this.accessLevel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageAccessLevelState &&
        other.view == view &&
        other.isLocked == isLocked &&
        other.lockCounter == lockCounter &&
        other.isLoadingLockStatus == isLoadingLockStatus &&
        other.accessLevel == accessLevel;
  }

  @override
  int get hashCode {
    return Object.hash(
      view,
      isLocked,
      lockCounter,
      isLoadingLockStatus,
      accessLevel,
    );
  }

  @override
  String toString() {
    return 'PageAccessLevelState(view: $view, isLocked: $isLocked, lockCounter: $lockCounter, isLoadingLockStatus: $isLoadingLockStatus, accessLevel: $accessLevel)';
  }
}
