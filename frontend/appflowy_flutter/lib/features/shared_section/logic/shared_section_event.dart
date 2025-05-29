import 'package:appflowy/features/shared_section/models/shared_page.dart';

/// Base class for all SharedSection events
sealed class SharedSectionEvent {
  const SharedSectionEvent();

  /// Initialize, it will create a folder notification listener to listen for shared view updates.
  /// Also, it will fetch the shared pages from the repository.
  const factory SharedSectionEvent.init() = SharedSectionInitEvent;

  /// Refresh, it will re-fetch the shared pages from the repository.
  const factory SharedSectionEvent.refresh() = SharedSectionRefreshEvent;

  /// Update the shared pages in the state.
  const factory SharedSectionEvent.updateSharedPages({
    required SharedPages sharedPages,
  }) = SharedSectionUpdateSharedPagesEvent;

  /// Toggle the expanded status of the shared section.
  const factory SharedSectionEvent.toggleExpanded() =
      SharedSectionToggleExpandedEvent;
}

class SharedSectionInitEvent extends SharedSectionEvent {
  const SharedSectionInitEvent();
}

class SharedSectionRefreshEvent extends SharedSectionEvent {
  const SharedSectionRefreshEvent();
}

class SharedSectionUpdateSharedPagesEvent extends SharedSectionEvent {
  const SharedSectionUpdateSharedPagesEvent({
    required this.sharedPages,
  });

  final SharedPages sharedPages;
}

class SharedSectionToggleExpandedEvent extends SharedSectionEvent {
  const SharedSectionToggleExpandedEvent();
}
