import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'view_selector_cubit.freezed.dart';

enum ViewSelectedStatus {
  unselected,
  selected,
  partiallySelected;

  bool get isUnselected => this == unselected;
  bool get isSelected => this == selected;
  bool get isPartiallySelected => this == partiallySelected;
}

class ViewSelectorItem {
  ViewSelectorItem({
    required this.view,
    required this.parentView,
    required this.children,
    required bool isExpanded,
    required ViewSelectedStatus selectedStatus,
    required bool isDisabled,
  })  : isExpandedNotifier = ValueNotifier(isExpanded),
        selectedStatusNotifier = ValueNotifier(selectedStatus),
        isDisabledNotifier = ValueNotifier(isDisabled);

  final ViewPB view;
  final ViewPB? parentView;
  final List<ViewSelectorItem> children;
  final ValueNotifier<bool> isExpandedNotifier;
  final ValueNotifier<bool> isDisabledNotifier;
  final ValueNotifier<ViewSelectedStatus> selectedStatusNotifier;

  bool get isExpanded => isExpandedNotifier.value;
  ViewSelectedStatus get selectedStatus => selectedStatusNotifier.value;
  bool get isDisabled => isDisabledNotifier.value;

  void toggleIsExpanded() {
    isExpandedNotifier.value = !isExpandedNotifier.value;
  }

  ViewSelectorItem copy() {
    return ViewSelectorItem(
      view: view,
      parentView: parentView,
      children:
          children.map<ViewSelectorItem>((child) => child.copy()).toList(),
      isDisabled: isDisabledNotifier.value,
      isExpanded: isExpandedNotifier.value,
      selectedStatus: selectedStatusNotifier.value,
    );
  }

  ViewSelectorItem? findChildBySourceId(String sourceId) {
    if (view.id == sourceId) {
      return this;
    }
    for (final child in children) {
      final childResult = child.findChildBySourceId(sourceId);
      if (childResult != null) {
        return childResult;
      }
    }
    return null;
  }

  void setIsDisabledRecursive(bool Function(ViewPB) newIsDisabled) {
    isDisabledNotifier.value = newIsDisabled(view);

    for (final child in children) {
      child.setIsDisabledRecursive(newIsDisabled);
    }
  }

  void setIsSelectedStatusRecursive(ViewSelectedStatus selectedStatus) {
    selectedStatusNotifier.value = selectedStatus;

    for (final child in children) {
      child.setIsSelectedStatusRecursive(selectedStatus);
    }
  }

  void dispose() {
    for (final child in children) {
      child.dispose();
    }
    isExpandedNotifier.dispose();
    selectedStatusNotifier.dispose();
    isDisabledNotifier.dispose();
  }
}

class ViewSelectorCubit extends Cubit<ViewSelectorState> {
  ViewSelectorCubit({
    required this.getIgnoreViewType,
    this.maxSelectedParentPageCount,
  }) : super(ViewSelectorState.initial()) {
    filterTextController.addListener(onFilterChanged);
  }

  final IgnoreViewType Function(ViewPB) getIgnoreViewType;
  final int? maxSelectedParentPageCount;

  final List<String> selectedSourceIds = [];
  final List<ViewSelectorItem> sources = [];
  final List<ViewSelectorItem> selectedSources = [];
  final filterTextController = TextEditingController();

  void updateSelectedSources(List<String> newSelectedSourceIds) {
    selectedSourceIds.clear();
    selectedSourceIds.addAll(newSelectedSourceIds);
  }

  Future<void> refreshSources(
    List<ViewPB> spaceViews,
    ViewPB? currentSpace,
  ) async {
    filterTextController.clear();

    final newSources = await Future.wait(
      spaceViews.map((view) => _recursiveBuild(view, null)),
    );

    _restrictSelectionIfNecessary(newSources);

    if (currentSpace != null) {
      newSources
          .firstWhereOrNull((e) => e.view.id == currentSpace.id)
          ?.toggleIsExpanded();
    }

    final selected = newSources
        .map((source) => _buildSelectedSources(source))
        .flattened
        .toList();

    emit(
      state.copyWith(
        selectedSources: selected,
        visibleSources: newSources,
      ),
    );

    sources
      ..forEach((e) => e.dispose())
      ..clear()
      ..addAll(newSources.map((e) => e.copy()));

    selectedSources
      ..forEach((e) => e.dispose())
      ..clear()
      ..addAll(selected.map((e) => e.copy()));
  }

  Future<ViewSelectorItem> _recursiveBuild(
    ViewPB view,
    ViewPB? parentView,
  ) async {
    ViewSelectedStatus selectedStatus = ViewSelectedStatus.unselected;
    final isThisSourceSelected = selectedSourceIds.contains(view.id);

    final List<ViewPB>? childrenViews;
    if (integrationMode().isTest) {
      childrenViews = view.childViews;
    } else {
      childrenViews =
          await ViewBackendService.getChildViews(viewId: view.id).toNullable();
    }

    int selectedCount = 0;
    final children = <ViewSelectorItem>[];

    if (childrenViews != null) {
      for (final childView in childrenViews) {
        if (getIgnoreViewType(childView) == IgnoreViewType.hide) {
          continue;
        }

        final childItem = await _recursiveBuild(childView, view);
        if (childItem.selectedStatus.isSelected) {
          selectedCount++;
        }
        children.add(childItem);
      }

      final areAllChildrenSelectedOrNoChildren =
          children.length == selectedCount;
      final isAnyChildNotUnselected =
          children.any((e) => !e.selectedStatus.isUnselected);

      if (isThisSourceSelected && areAllChildrenSelectedOrNoChildren) {
        selectedStatus = ViewSelectedStatus.selected;
      } else if (isThisSourceSelected || isAnyChildNotUnselected) {
        selectedStatus = ViewSelectedStatus.partiallySelected;
      }
    } else if (isThisSourceSelected) {
      selectedStatus = ViewSelectedStatus.selected;
    }

    return ViewSelectorItem(
      view: view,
      parentView: parentView,
      children: children,
      isDisabled: getIgnoreViewType(view) == IgnoreViewType.disable,
      isExpanded: false,
      selectedStatus: selectedStatus,
    );
  }

  void _restrictSelectionIfNecessary(List<ViewSelectorItem> sources) {
    if (maxSelectedParentPageCount == null) {
      return;
    }
    for (final source in sources) {
      source.setIsDisabledRecursive((view) {
        return getIgnoreViewType(view) == IgnoreViewType.disable;
      });
    }
    if (sources.where((e) => !e.selectedStatus.isUnselected).length >=
        maxSelectedParentPageCount!) {
      sources
          .where((e) => e.selectedStatus == ViewSelectedStatus.unselected)
          .forEach(
            (e) => e.setIsDisabledRecursive((_) => true),
          );
    }
  }

  void onFilterChanged() {
    for (final source in state.visibleSources) {
      source.dispose();
    }
    if (sources.isEmpty) {
      emit(ViewSelectorState.initial());
    } else {
      final selected =
          selectedSources.map(_buildSearchResults).nonNulls.toList();
      final visible =
          sources.map(_buildSearchResults).nonNulls.nonNulls.toList();
      emit(
        state.copyWith(
          selectedSources: selected,
          visibleSources: visible,
        ),
      );
    }
  }

  /// traverse tree to build up search query
  ViewSelectorItem? _buildSearchResults(ViewSelectorItem item) {
    final isVisible = item.view.nameOrDefault
        .toLowerCase()
        .contains(filterTextController.text.toLowerCase());

    final childrenResults = <ViewSelectorItem>[];
    for (final childSource in item.children) {
      final childResult = _buildSearchResults(childSource);
      if (childResult != null) {
        childrenResults.add(childResult);
      }
    }

    return isVisible || childrenResults.isNotEmpty
        ? ViewSelectorItem(
            view: item.view,
            parentView: item.parentView,
            children: childrenResults,
            isDisabled: item.isDisabled,
            isExpanded: item.isExpanded,
            selectedStatus: item.selectedStatus,
          )
        : null;
  }

  /// traverse tree to build up selected sources
  Iterable<ViewSelectorItem> _buildSelectedSources(
    ViewSelectorItem item,
  ) {
    final children = <ViewSelectorItem>[];

    for (final childSource in item.children) {
      children.addAll(_buildSelectedSources(childSource));
    }

    return selectedSourceIds.contains(item.view.id)
        ? [
            ViewSelectorItem(
              view: item.view,
              parentView: item.parentView,
              children: children,
              isDisabled: item.isDisabled,
              selectedStatus: item.selectedStatus,
              isExpanded: true,
            ),
          ]
        : children;
  }

  void toggleSelectedStatus(ViewSelectorItem item, bool isSelectedSection) {
    if (item.view.isSpace) {
      return;
    }
    final allIds = _recursiveGetSourceIds(item);

    if (item.selectedStatus.isUnselected ||
        item.selectedStatus.isPartiallySelected &&
            !item.view.layout.isDocumentView) {
      for (final id in allIds) {
        if (!selectedSourceIds.contains(id)) {
          selectedSourceIds.add(id);
        }
      }
    } else {
      for (final id in allIds) {
        if (selectedSourceIds.contains(id)) {
          selectedSourceIds.remove(id);
        }
      }
    }

    if (isSelectedSection) {
      item.setIsSelectedStatusRecursive(
        item.selectedStatus.isUnselected ||
                item.selectedStatus.isPartiallySelected
            ? ViewSelectedStatus.selected
            : ViewSelectedStatus.unselected,
      );
    }

    updateSelectedStatus();
  }

  List<String> _recursiveGetSourceIds(ViewSelectorItem item) {
    return [
      if (item.view.layout.isDocumentView) item.view.id,
      for (final childSource in item.children)
        ..._recursiveGetSourceIds(childSource),
    ];
  }

  void updateSelectedStatus() {
    if (sources.isEmpty) {
      return;
    }
    for (final source in sources) {
      _recursiveUpdateSelectedStatus(source);
    }
    _restrictSelectionIfNecessary(sources);
    for (final visibleSource in state.visibleSources) {
      visibleSource.dispose();
    }
    final visible = sources.map(_buildSearchResults).nonNulls.toList();

    emit(
      state.copyWith(
        visibleSources: visible,
      ),
    );
  }

  ViewSelectedStatus _recursiveUpdateSelectedStatus(ViewSelectorItem item) {
    ViewSelectedStatus selectedStatus = ViewSelectedStatus.unselected;

    int selectedCount = 0;
    for (final childSource in item.children) {
      final childStatus = _recursiveUpdateSelectedStatus(childSource);
      if (childStatus.isSelected) {
        selectedCount++;
      }
    }

    final isThisSourceSelected = selectedSourceIds.contains(item.view.id);
    final areAllChildrenSelectedOrNoChildren =
        item.children.length == selectedCount;
    final isAnyChildNotUnselected =
        item.children.any((e) => !e.selectedStatus.isUnselected);

    if (isThisSourceSelected && areAllChildrenSelectedOrNoChildren) {
      selectedStatus = ViewSelectedStatus.selected;
    } else if (isThisSourceSelected || isAnyChildNotUnselected) {
      selectedStatus = ViewSelectedStatus.partiallySelected;
    }

    item.selectedStatusNotifier.value = selectedStatus;
    return selectedStatus;
  }

  void toggleIsExpanded(ViewSelectorItem item, bool isSelectedSection) {
    item.toggleIsExpanded();
    if (isSelectedSection) {
      for (final selectedSource in selectedSources) {
        selectedSource.findChildBySourceId(item.view.id)?.toggleIsExpanded();
      }
    } else {
      for (final source in sources) {
        final child = source.findChildBySourceId(item.view.id);
        if (child != null) {
          child.toggleIsExpanded();
          break;
        }
      }
    }
  }

  @override
  Future<void> close() {
    for (final child in sources) {
      child.dispose();
    }
    for (final child in selectedSources) {
      child.dispose();
    }
    for (final child in state.selectedSources) {
      child.dispose();
    }
    for (final child in state.visibleSources) {
      child.dispose();
    }
    filterTextController.dispose();
    return super.close();
  }
}

@freezed
class ViewSelectorState with _$ViewSelectorState {
  const factory ViewSelectorState({
    required List<ViewSelectorItem> visibleSources,
    required List<ViewSelectorItem> selectedSources,
  }) = _ViewSelectorState;

  factory ViewSelectorState.initial() => const ViewSelectorState(
        visibleSources: [],
        selectedSources: [],
      );
}
