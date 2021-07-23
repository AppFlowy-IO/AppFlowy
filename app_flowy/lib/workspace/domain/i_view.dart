abstract class IViewWatch {
  void startWatching({ViewUpdatedCallback? updatedCallback});

  Future<void> stopWatching();
}
