/// The access level a user can have on a shared page.
enum ShareAccessLevel {
  /// Can view the page only.
  readOnly,

  /// Can read and comment on the page.
  readAndComment,

  /// Can read and write to the page.
  readAndWrite,

  /// Full access (edit, share, remove, etc.) and can add new users.
  fullAccess;

  String get i18n {
    switch (this) {
      case ShareAccessLevel.readOnly:
        return 'View';
      case ShareAccessLevel.readAndComment:
        return 'Comment';
      case ShareAccessLevel.readAndWrite:
        return 'Edit';
      case ShareAccessLevel.fullAccess:
        return 'Full access';
    }
  }
}
