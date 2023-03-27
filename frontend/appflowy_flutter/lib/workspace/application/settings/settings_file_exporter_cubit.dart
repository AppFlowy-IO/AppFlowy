import 'package:appflowy_backend/protobuf/flowy-folder2/app.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsFileExportState {
  SettingsFileExportState({
    required this.apps,
  }) {
    initialize();
  }

  List<ViewPB> apps;
  List<bool> expanded = [];
  List<bool> selectedApps = [];
  List<List<bool>> selectedItems = [];

  SettingsFileExportState copyWith({
    List<ViewPB>? apps,
    List<bool>? expanded,
    List<bool>? selectedApps,
    List<List<bool>>? selectedItems,
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
    expanded = apps.map((e) => true).toList();
    selectedApps = apps.map((e) => true).toList();
    selectedItems =
        apps.map((e) => e.belongings.map((e) => true).toList()).toList();
  }
}

class SettingsFileExporterCubit extends Cubit<SettingsFileExportState> {
  SettingsFileExporterCubit({
    required List<ViewPB> apps,
  }) : super(SettingsFileExportState(apps: apps));

  void selectOrDeselectItem(int outerIndex, int innerIndex) {
    final selectedItems = state.selectedItems;
    selectedItems[outerIndex][innerIndex] =
        !selectedItems[outerIndex][innerIndex];
    emit(state.copyWith(selectedItems: selectedItems));
  }

  void expandOrUnexpandApp(int outerIndex) {
    final expanded = state.expanded;
    expanded[outerIndex] = !expanded[outerIndex];
    emit(state.copyWith(expanded: expanded));
  }

  Map<String, List<String>> fetchSelectedPages() {
    final apps = state.apps;
    final selectedItems = state.selectedItems;
    Map<String, List<String>> result = {};
    for (var i = 0; i < selectedItems.length; i++) {
      final selectedItem = selectedItems[i];
      final ids = <String>[];
      for (var j = 0; j < selectedItem.length; j++) {
        if (selectedItem[j]) {
          ids.add(apps[i].belongings[j].id);
        }
      }
      if (ids.isNotEmpty) {
        result[apps[i].id] = ids;
      }
    }
    return result;
  }
}
