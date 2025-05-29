/// Base class for all PageAccessLevel events
sealed class PageAccessLevelEvent {
  const PageAccessLevelEvent();

  /// Initialize the view lock status, it will create a view listener to listen for view updates.
  /// Also, it will fetch the current view lock status from the repository.
  const factory PageAccessLevelEvent.initial() = PageAccessLevelInitialEvent;

  /// Lock the view.
  const factory PageAccessLevelEvent.lock() = PageAccessLevelLockEvent;

  /// Unlock the view.
  const factory PageAccessLevelEvent.unlock() = PageAccessLevelUnlockEvent;

  /// Update the lock status in the state.
  const factory PageAccessLevelEvent.updateLockStatus(
    bool isLocked, {
    int? lockCounter,
  }) = PageAccessLevelUpdateLockStatusEvent;
}

class PageAccessLevelInitialEvent extends PageAccessLevelEvent {
  const PageAccessLevelInitialEvent();
}

class PageAccessLevelLockEvent extends PageAccessLevelEvent {
  const PageAccessLevelLockEvent();
}

class PageAccessLevelUnlockEvent extends PageAccessLevelEvent {
  const PageAccessLevelUnlockEvent();
}

class PageAccessLevelUpdateLockStatusEvent extends PageAccessLevelEvent {
  const PageAccessLevelUpdateLockStatusEvent(
    this.isLocked, {
    this.lockCounter,
  });

  final bool isLocked;
  final int? lockCounter;
}
