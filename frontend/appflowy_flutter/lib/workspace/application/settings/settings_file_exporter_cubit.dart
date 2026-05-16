import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsFileExportState {
  SettingsFileExportState({
    required this.views,
  }) {
    initialize();
  }

  List<ViewPB> get selectedViews {
    final selectedViews = <ViewPB>[];
    for (var i = 0; i < views.length; i++) {
      if (selectedApps[i]) {
        for (var j = 0; j < views[i].childViews.length; j++) {
          if (selectedItems[i][j]) {
            selectedViews.add(views[i].childViews[j]);
          }
        }
      }
    }
    return selectedViews;
  }

  List<ViewPB> views;
  List<bool> expanded = [];
  List<bool> selectedApps = [];
  List<List<bool>> selectedItems = [];

  SettingsFileExportState copyWith({
    List<ViewPB>? views,
    List<bool>? expanded,
    List<bool>? selectedApps,
    List<List<bool>>? selectedItems,
  }) {
    final state = SettingsFileExportState(
      views: views ?? this.views,
    );
    state.expanded = expanded ?? this.expanded;
    state.selectedApps = selectedApps ?? this.selectedApps;
    state.selectedItems = selectedItems ?? this.selectedItems;
    return state;
  }

  void initialize() {
    expanded = views.map((e) => true).toList();
    selectedApps = views.map((e) => true).toList();
    selectedItems =
        views.map((e) => e.childViews.map((e) => true).toList()).toList();
  }
}

class SettingsFileExporterCubit extends Cubit<SettingsFileExportState> {
  SettingsFileExporterCubit({
    required List<ViewPB> views,
  }) : super(SettingsFileExportState(views: views));

  void selectOrDeselectAllItems() {
    final List<List<bool>> selectedItems = state.selectedItems;
    final isSelectAll =
        selectedItems.expand((element) => element).every((element) => element);
    for (var i = 0; i < selectedItems.length; i++) {
      for (var j = 0; j < selectedItems[i].length; j++) {
        selectedItems[i][j] = !isSelectAll;
      }
    }
    emit(state.copyWith(selectedItems: selectedItems));
  }

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
    final views = state.views;
    final selectedItems = state.selectedItems;
    final Map<String, List<String>> result = {};
    for (var i = 0; i < selectedItems.length; i++) {
      final selectedItem = selectedItems[i];
      final ids = <String>[];
      for (var j = 0; j < selectedItem.length; j++) {
        if (selectedItem[j]) {
          ids.add(views[i].childViews[j].id);
        }
      }
      if (ids.isNotEmpty) {
        result[views[i].id] = ids;
      }
    }
    return result;
  }
}
