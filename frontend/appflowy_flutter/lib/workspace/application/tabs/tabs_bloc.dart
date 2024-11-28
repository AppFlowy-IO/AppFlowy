import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tabs_bloc.freezed.dart';

class TabsBloc extends Bloc<TabsEvent, TabsState> {
  TabsBloc() : super(TabsState()) {
    menuSharedState = getIt<MenuSharedState>();
    _dispatch();
  }

  late final MenuSharedState menuSharedState;

  @override
  Future<void> close() {
    state.dispose();
    return super.close();
  }

  void _dispatch() {
    on<TabsEvent>(
      (event, emit) async {
        event.when(
          selectTab: (int index) {
            if (index != state.currentIndex &&
                index >= 0 &&
                index < state.pages) {
              emit(state.copyWith(newIndex: index));
              _setLatestOpenView();
            }
          },
          moveTab: () {},
          closeTab: (String pluginId) {
            final pm = state._pageManagers
                .firstWhereOrNull((pm) => pm.plugin.id == pluginId);
            if (pm?.isPinned == true) {
              return;
            }

            emit(state.closeView(pluginId));
            _setLatestOpenView();
          },
          closeCurrentTab: () {
            if (state.currentPageManager.isPinned) {
              return;
            }

            emit(state.closeView(state.currentPageManager.plugin.id));
            _setLatestOpenView();
          },
          openTab: (Plugin plugin, ViewPB view) {
            emit(state.openView(plugin, view));
            _setLatestOpenView(view);
          },
          openPlugin: (Plugin plugin, ViewPB? view, bool setLatest) {
            emit(state.openPlugin(plugin: plugin, setLatest: setLatest));
            if (setLatest) {
              _setLatestOpenView(view);
            }
          },
          closeOtherTabs: (String pluginId) {
            final pagesToClose = [
              ...state._pageManagers
                  .where((pm) => pm.plugin.id != pluginId && !pm.isPinned),
            ];

            final newstate = state;
            for (final pm in pagesToClose) {
              newstate.closeView(pm.plugin.id);
            }
            emit(newstate.copyWith(newIndex: 0));
            _setLatestOpenView();
          },
          togglePin: (String pluginId) {
            final pm = state._pageManagers
                .firstWhereOrNull((pm) => pm.plugin.id == pluginId);
            if (pm != null) {
              pm.isPinned = !pm.isPinned;
              emit(state.copyWith(pageManagers: [...state._pageManagers]));
            }
          },
        );
      },
    );
  }

  void _setLatestOpenView([ViewPB? view]) {
    if (view != null) {
      menuSharedState.latestOpenView = view;
    } else {
      final pageManager = state.currentPageManager;
      final notifier = pageManager.plugin.notifier;
      if (notifier is ViewPluginNotifier &&
          menuSharedState.latestOpenView?.id != notifier.view.id) {
        menuSharedState.latestOpenView = notifier.view;
      }
    }
  }

  /// Adds a [TabsEvent.openTab] event for the provided [ViewPB]
  void openTab(ViewPB view) =>
      add(TabsEvent.openTab(plugin: view.plugin(), view: view));

  /// Adds a [TabsEvent.openPlugin] event for the provided [ViewPB]
  void openPlugin(
    ViewPB view, {
    Map<String, dynamic> arguments = const {},
  }) {
    add(
      TabsEvent.openPlugin(
        plugin: view.plugin(arguments: arguments),
        view: view,
      ),
    );
  }
}

@freezed
class TabsEvent with _$TabsEvent {
  const factory TabsEvent.moveTab() = _MoveTab;
  const factory TabsEvent.closeTab(String pluginId) = _CloseTab;
  const factory TabsEvent.closeOtherTabs(String pluginId) = _CloseOtherTabs;
  const factory TabsEvent.closeCurrentTab() = _CloseCurrentTab;
  const factory TabsEvent.selectTab(int index) = _SelectTab;
  const factory TabsEvent.togglePin(String pluginId) = _TogglePin;
  const factory TabsEvent.openTab({
    required Plugin plugin,
    required ViewPB view,
  }) = _OpenTab;
  const factory TabsEvent.openPlugin({
    required Plugin plugin,
    ViewPB? view,
    @Default(true) bool setLatest,
  }) = _OpenPlugin;
}

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
      _pageManagers.add(PageManager()..setPlugin(plugin, true));

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
  TabsState openPlugin({required Plugin plugin, bool setLatest = true}) {
    final selectExistingPlugin = _selectPluginIfOpen(plugin.id);

    if (selectExistingPlugin == null) {
      final pageManagers = [..._pageManagers];
      pageManagers[currentIndex].setPlugin(plugin, setLatest);

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
