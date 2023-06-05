import 'package:appflowy_backend/protobuf/flowy-folder/app.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsFileExportState {
  SettingsFileExportState({
    required this.apps,
  }) {
    initialize();
  }

  List<ViewPB> get selectedViews {
    final selectedViews = <ViewPB>[];
    for (var i = 0; i < apps.length; i++) {
      if (selectedApps[i]) {
        for (var j = 0; j < apps[i].belongings.items.length; j++) {
          if (selectedItems[i][j]) {
            selectedViews.add(apps[i].belongings.items[j]);
          }
        }
      }
    }
    return selectedViews;
  }

  List<AppPB> apps;
  List<bool> expanded = [];
  List<bool> selectedApps = [];
  List<List<bool>> selectedItems = [];

  SettingsFileExportState copyWith({
    final List<AppPB>? apps,
    final List<bool>? expanded,
    final List<bool>? selectedApps,
    final List<List<bool>>? selectedItems,
  }) {
    final state = SettingsFileExportState(
      apps: apps ?? this.apps,
    );
    state.expanded = expanded ?? this.expanded;
    state.selectedApps = selectedApps ?? this.selectedApps;
    state.selectedItems = selectedItems ?? this.selectedItems;
    return state;
  }

  void initialize() {
    expanded = apps.map((final e) => true).toList();
    selectedApps = apps.map((final e) => true).toList();
    selectedItems = apps
        .map((final e) => e.belongings.items.map((final e) => true).toList())
        .toList();
  }
}

class SettingsFileExporterCubit extends Cubit<SettingsFileExportState> {
  SettingsFileExporterCubit({
    required final List<AppPB> apps,
  }) : super(SettingsFileExportState(apps: apps));

  void selectOrDeselectItem(final int outerIndex, final int innerIndex) {
    final selectedItems = state.selectedItems;
    selectedItems[outerIndex][innerIndex] =
        !selectedItems[outerIndex][innerIndex];
    emit(state.copyWith(selectedItems: selectedItems));
  }

  void expandOrUnexpandApp(final int outerIndex) {
    final expanded = state.expanded;
    expanded[outerIndex] = !expanded[outerIndex];
    emit(state.copyWith(expanded: expanded));
  }

  Map<String, List<String>> fetchSelectedPages() {
    final apps = state.apps;
    final selectedItems = state.selectedItems;
    final Map<String, List<String>> result = {};
    for (var i = 0; i < selectedItems.length; i++) {
      final selectedItem = selectedItems[i];
      final ids = <String>[];
      for (var j = 0; j < selectedItem.length; j++) {
        if (selectedItem[j]) {
          ids.add(apps[i].belongings.items[j].id);
        }
      }
      if (ids.isNotEmpty) {
        result[apps[i].id] = ids;
      }
    }
    return result;
  }
}
