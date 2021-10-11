enum ViewAction {
  rename,
  delete,
}

extension ViewActionExtension on ViewAction {
  String get name {
    switch (this) {
      case ViewAction.rename:
        return 'rename';
      case ViewAction.delete:
        return 'delete';
      default:
        return '';
    }
  }
}
