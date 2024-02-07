part of 'tabs_bloc.dart';

class TabsState {
  TabsState({
    this.currentIndex = 0,
    List<PageManager>? pageManagers,
  }) : _pageManagers = pageManagers ?? [PageManager()];

  final int currentIndex;
  final List<PageManager> _pageManagers;
  int get pages => _pageManagers.length;
  PageManager get currentPageManager => _pageManagers[currentIndex];
  List<PageManager> get pageManagers => _pageManagers;

  /// This opens a new tab given a [Plugin] and a [View].
  ///
  /// If the [Plugin.id] is already associated with an open tab,
  /// then it selects that tab.
  ///
  TabsState openView(Plugin plugin, ViewPB view) {
    final selectExistingPlugin = _selectPluginIfOpen(plugin.id);

    if (selectExistingPlugin == null) {
      _pageManagers.add(PageManager()..setPlugin(plugin));

      return copyWith(newIndex: pages - 1, pageManagers: [..._pageManagers]);
    }

    return selectExistingPlugin;
  }

  TabsState closeView(String pluginId) {
    // Avoid closing the only open tab
    if (_pageManagers.length == 1) {
      return this;
    }

    _pageManagers.removeWhere((pm) => pm.plugin.id == pluginId);

    /// If currentIndex is greater than the amount of allowed indices
    /// And the current selected tab isn't the first (index 0)
    ///   as currentIndex cannot be -1
    /// Then decrease currentIndex by 1
    final newIndex = currentIndex > pages - 1 && currentIndex > 0
        ? currentIndex - 1
        : currentIndex;

    return copyWith(
      newIndex: newIndex,
      pageManagers: [..._pageManagers],
    );
  }

  /// This opens a plugin in the current selected tab,
  /// due to how Document currently works, only one tab
  /// per plugin can currently be active.
  ///
  /// If the plugin is already open in a tab, then that tab
  /// will become selected.
  ///
  TabsState openPlugin({required Plugin plugin}) {
    final selectExistingPlugin = _selectPluginIfOpen(plugin.id);

    if (selectExistingPlugin == null) {
      final pageManagers = [..._pageManagers];
      pageManagers[currentIndex].setPlugin(plugin);

      return copyWith(pageManagers: pageManagers);
    }

    return selectExistingPlugin;
  }

  /// Checks if a [Plugin.id] is already associated with an open tab.
  /// Returns a [TabState] with new index if there is a match.
  ///
  /// If no match it returns null
  ///
  TabsState? _selectPluginIfOpen(String id) {
    final index = _pageManagers.indexWhere((pm) => pm.plugin.id == id);

    if (index == -1) {
      return null;
    }

    if (index == currentIndex) {
      return this;
    }

    return copyWith(newIndex: index);
  }

  TabsState copyWith({
    int? newIndex,
    List<PageManager>? pageManagers,
  }) =>
      TabsState(
        currentIndex: newIndex ?? currentIndex,
        pageManagers: pageManagers ?? _pageManagers,
      );

  void dispose() {
    for (final manager in pageManagers) {
      manager.dispose();
    }
  }
}
