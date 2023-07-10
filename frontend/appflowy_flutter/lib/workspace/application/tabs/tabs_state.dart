part of 'tabs_bloc.dart';

class TabsState {
  final int currentIndex;

  final List<PageManager> _pageManagers;
  int get pages => _pageManagers.length;
  PageManager get currentPageManager => _pageManagers[currentIndex];
  List<PageManager> get pageManagers => _pageManagers;

  TabsState({
    this.currentIndex = 0,
    List<PageManager>? pageManagers,
  }) : _pageManagers = pageManagers ?? [PageManager()];

  /// This opens a new tab, only if the id of the plugin
  /// being opened, is disimilar to all currently open tabs.
  ///
  TabsState openView(Plugin plugin, ViewPB view) {
    final existingIndex = _pageManagers.indexWhere(
      (pm) => pm.plugin.id == plugin.id,
    );

    if (existingIndex != -1) {
      return copyWith(newIndex: existingIndex);
    }

    _pageManagers.add(PageManager()..setPlugin(plugin));

    return copyWith(newIndex: pages - 1, pageManagers: [..._pageManagers]);
  }

  TabsState closeView(String pluginId) {
    _pageManagers.removeWhere((pm) => pm.plugin.id == pluginId);

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
    final existingIndex =
        _pageManagers.indexWhere((pm) => pm.plugin.id == plugin.id);

    if (existingIndex != -1) {
      return copyWith(newIndex: existingIndex);
    }

    final pageManagers = [..._pageManagers];
    pageManagers[currentIndex].setPlugin(plugin);

    return copyWith(pageManagers: pageManagers);
  }

  TabsState copyWith({
    int? newIndex,
    List<PageManager>? pageManagers,
  }) =>
      TabsState(
        currentIndex: newIndex ?? currentIndex,
        pageManagers: pageManagers ?? _pageManagers,
      );
}
