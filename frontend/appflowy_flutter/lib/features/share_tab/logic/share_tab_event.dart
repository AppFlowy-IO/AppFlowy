import 'package:appflowy/features/share_tab/data/models/models.dart';

sealed class ShareTabEvent {
  const ShareTabEvent();

  // Factory functions for creating events
  factory ShareTabEvent.initialize() => const ShareTabEventInitialize();

  factory ShareTabEvent.loadSharedUsers() =>
      const ShareTabEventLoadSharedUsers();

  factory ShareTabEvent.inviteUsers({
    required List<String> emails,
    required ShareAccessLevel accessLevel,
  }) =>
      ShareTabEventInviteUsers(emails: emails, accessLevel: accessLevel);

  factory ShareTabEvent.removeUsers({
    required List<String> emails,
  }) =>
      ShareTabEventRemoveUsers(emails: emails);

  factory ShareTabEvent.updateUserAccessLevel({
    required String email,
    required ShareAccessLevel accessLevel,
  }) =>
      ShareTabEventUpdateUserAccessLevel(
        email: email,
        accessLevel: accessLevel,
      );

  factory ShareTabEvent.updateGeneralAccessLevel({
    required ShareAccessLevel accessLevel,
  }) =>
      ShareTabEventUpdateGeneralAccessLevel(accessLevel: accessLevel);

  factory ShareTabEvent.copyShareLink({
    required String link,
  }) =>
      ShareTabEventCopyShareLink(link: link);

  factory ShareTabEvent.searchAvailableUsers({
    required String query,
  }) =>
      ShareTabEventSearchAvailableUsers(query: query);

  factory ShareTabEvent.convertToMember({
    required String email,
  }) =>
      ShareTabEventConvertToMember(email: email);

  factory ShareTabEvent.clearState() => const ShareTabEventClearState();

  factory ShareTabEvent.updateSharedUsers({
    required SharedUsers users,
  }) =>
      ShareTabEventUpdateSharedUsers(users: users);
}

/// Initializes the share tab bloc.
class ShareTabEventInitialize extends ShareTabEvent {
  const ShareTabEventInitialize();
}

/// Loads the shared users for the current page.
class ShareTabEventLoadSharedUsers extends ShareTabEvent {
  const ShareTabEventLoadSharedUsers();
}

/// Invites users to the page with specified access level.
class ShareTabEventInviteUsers extends ShareTabEvent {
  const ShareTabEventInviteUsers({
    required this.emails,
    required this.accessLevel,
  });

  final List<String> emails;
  final ShareAccessLevel accessLevel;
}

/// Removes users from the shared page.
class ShareTabEventRemoveUsers extends ShareTabEvent {
  const ShareTabEventRemoveUsers({
    required this.emails,
  });

  final List<String> emails;
}

/// Updates the access level for a specific user.
class ShareTabEventUpdateUserAccessLevel extends ShareTabEvent {
  const ShareTabEventUpdateUserAccessLevel({
    required this.email,
    required this.accessLevel,
  });

  final String email;
  final ShareAccessLevel accessLevel;
}

/// Updates the general access level for all users.
class ShareTabEventUpdateGeneralAccessLevel extends ShareTabEvent {
  const ShareTabEventUpdateGeneralAccessLevel({
    required this.accessLevel,
  });

  final ShareAccessLevel accessLevel;
}

/// Copies the share link to the clipboard.
class ShareTabEventCopyShareLink extends ShareTabEvent {
  const ShareTabEventCopyShareLink({
    required this.link,
  });

  final String link;
}

/// Searches for available users by name or email.
class ShareTabEventSearchAvailableUsers extends ShareTabEvent {
  const ShareTabEventSearchAvailableUsers({
    required this.query,
  });

  final String query;
}

/// Converts a user into a member.
class ShareTabEventConvertToMember extends ShareTabEvent {
  const ShareTabEventConvertToMember({
    required this.email,
  });

  final String email;
}

class ShareTabEventClearState extends ShareTabEvent {
  const ShareTabEventClearState();
}

class ShareTabEventUpdateSharedUsers extends ShareTabEvent {
  const ShareTabEventUpdateSharedUsers({
    required this.users,
  });

  final SharedUsers users;
}
