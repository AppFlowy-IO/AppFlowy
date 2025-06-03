import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

class PageAccessLevelState {
  factory PageAccessLevelState.initial(ViewPB view) => PageAccessLevelState(
        view: view,
        isLocked: false,
        lockCounter: 0,
        sectionType: SharedSectionType.public,
        accessLevel: ShareAccessLevel
            .readAndWrite, // replace it with readOnly if we support offline.
      );

  const PageAccessLevelState({
    required this.view,
    required this.isLocked,
    required this.lockCounter,
    required this.accessLevel,
    required this.sectionType,
    this.myRole,
    this.isLoadingLockStatus = true,
  });

  final ViewPB view;
  final bool isLocked;
  final int lockCounter;
  final bool isLoadingLockStatus;
  final ShareAccessLevel accessLevel;
  final SharedSectionType sectionType;
  final ShareRole? myRole;

  bool get isPublic => sectionType == SharedSectionType.public;
  bool get isPrivate => sectionType == SharedSectionType.private;
  bool get isShared => sectionType == SharedSectionType.shared;
  bool get shouldHideSpace => myRole == ShareRole.guest;

  bool get isEditable {
    if (!FeatureFlag.sharedSection.isOn) {
      return !isLocked;
    }

    return accessLevel != ShareAccessLevel.readOnly && !isLocked;
  }

  bool get isReadOnly => accessLevel == ShareAccessLevel.readOnly;

  PageAccessLevelState copyWith({
    ViewPB? view,
    bool? isLocked,
    int? lockCounter,
    bool? isLoadingLockStatus,
    ShareAccessLevel? accessLevel,
    SharedSectionType? sectionType,
    ShareRole? myRole,
  }) {
    return PageAccessLevelState(
      view: view ?? this.view,
      isLocked: isLocked ?? this.isLocked,
      lockCounter: lockCounter ?? this.lockCounter,
      isLoadingLockStatus: isLoadingLockStatus ?? this.isLoadingLockStatus,
      accessLevel: accessLevel ?? this.accessLevel,
      sectionType: sectionType ?? this.sectionType,
      myRole: myRole ?? this.myRole,
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
        other.accessLevel == accessLevel &&
        other.sectionType == sectionType &&
        other.myRole == myRole;
  }

  @override
  int get hashCode {
    return Object.hash(
      view,
      isLocked,
      lockCounter,
      isLoadingLockStatus,
      accessLevel,
      sectionType,
      myRole,
    );
  }

  @override
  String toString() {
    return 'PageAccessLevelState(view: $view, isLocked: $isLocked, lockCounter: $lockCounter, isLoadingLockStatus: $isLoadingLockStatus, accessLevel: $accessLevel, sectionType: $sectionType, myRole: $myRole)';
  }
}
