import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_input_control_cubit.freezed.dart';

class ChatInputControlCubit extends Cubit<ChatInputControlState> {
  ChatInputControlCubit() : super(const ChatInputControlState.loading());

  final List<ViewPB> allViews = [];
  final List<String> selectedViewIds = [];

  /// used when mentioning a page
  ///
  /// the text position after the @ character
  int _filterStartPosition = -1;

  /// used when mentioning a page
  ///
  /// the text position after the @ character, at the end of the filter
  int _filterEndPosition = -1;

  /// used when mentioning a page
  ///
  /// the entire string input in the prompt
  String _inputText = "";

  /// used when mentioning a page
  ///
  /// the current filtering text, after the @ characater
  String _filter = "";

  String get inputText => _inputText;
  int get filterStartPosition => _filterStartPosition;
  int get filterEndPosition => _filterEndPosition;

  void refreshViews() async {
    final newViews = await ViewBackendService.getAllViews().fold(
      (result) {
        return result.items
            .where((v) => v.layout.isDocumentView && v.parentViewId != v.id)
            .toList();
      },
      (err) {
        Log.error(err);
        return <ViewPB>[];
      },
    );
    allViews
      ..clear()
      ..addAll(newViews);

    // update visible views
    newViews.retainWhere((v) => !selectedViewIds.contains(v.id));
    if (_filter.isNotEmpty) {
      newViews.retainWhere(
        (v) {
          final nonEmptyName = v.name.isEmpty
              ? LocaleKeys.document_title_placeholder.tr()
              : v.name;
          return nonEmptyName.toLowerCase().contains(_filter);
        },
      );
    }
    final focusedViewIndex = newViews.isEmpty ? -1 : 0;
    emit(
      ChatInputControlState.ready(
        visibleViews: newViews,
        focusedViewIndex: focusedViewIndex,
      ),
    );
  }

  void startSearching(TextEditingValue textEditingValue) {
    _filterStartPosition =
        _filterEndPosition = textEditingValue.selection.baseOffset;
    _filter = "";
    _inputText = textEditingValue.text;
    state.maybeMap(
      ready: (readyState) {
        emit(
          readyState.copyWith(
            visibleViews: allViews,
            focusedViewIndex: allViews.isEmpty ? -1 : 0,
          ),
        );
      },
      orElse: () {},
    );
  }

  void reset() {
    _filterStartPosition = _filterEndPosition = -1;
    _filter = _inputText = "";
    state.maybeMap(
      ready: (readyState) {
        emit(
          readyState.copyWith(
            visibleViews: allViews,
            focusedViewIndex: allViews.isEmpty ? -1 : 0,
          ),
        );
      },
      orElse: () {},
    );
  }

  void updateFilter(
    String newInputText,
    String newFilter, {
    int? newEndPosition,
  }) {
    updateInputText(newInputText);

    // filter the views
    _filter = newFilter.toLowerCase();
    if (newEndPosition != null) {
      _filterEndPosition = newEndPosition;
    }

    final newVisibleViews =
        allViews.where((v) => !selectedViewIds.contains(v.id)).toList();

    if (_filter.isNotEmpty) {
      newVisibleViews.retainWhere(
        (v) {
          final nonEmptyName = v.name.isEmpty
              ? LocaleKeys.document_title_placeholder.tr()
              : v.name;
          return nonEmptyName.toLowerCase().contains(_filter);
        },
      );
    }

    state.maybeWhen(
      ready: (_, oldFocusedIndex) {
        final newFocusedViewIndex = oldFocusedIndex < newVisibleViews.length
            ? oldFocusedIndex
            : (newVisibleViews.isEmpty ? -1 : 0);
        emit(
          ChatInputControlState.ready(
            visibleViews: newVisibleViews,
            focusedViewIndex: newFocusedViewIndex,
          ),
        );
      },
      orElse: () {},
    );
  }

  void updateInputText(String newInputText) {
    _inputText = newInputText;

    // input text is changed, see if there are any deletions
    selectedViewIds.retainWhere(_inputText.contains);
    _notifyUpdateSelectedViews();
  }

  void updateSelectionUp() {
    state.maybeMap(
      ready: (readyState) {
        final newIndex = readyState.visibleViews.isEmpty
            ? -1
            : (readyState.focusedViewIndex - 1) %
                readyState.visibleViews.length;
        emit(
          readyState.copyWith(focusedViewIndex: newIndex),
        );
      },
      orElse: () {},
    );
  }

  void updateSelectionDown() {
    state.maybeMap(
      ready: (readyState) {
        final newIndex = readyState.visibleViews.isEmpty
            ? -1
            : (readyState.focusedViewIndex + 1) %
                readyState.visibleViews.length;
        emit(
          readyState.copyWith(focusedViewIndex: newIndex),
        );
      },
      orElse: () {},
    );
  }

  void selectPage(ViewPB view) {
    selectedViewIds.add(view.id);
    _notifyUpdateSelectedViews();
    reset();
  }

  String formatIntputText(final String input) {
    String result = input;
    for (final viewId in selectedViewIds) {
      if (!result.contains(viewId)) {
        continue;
      }
      final view = allViews.firstWhereOrNull((view) => view.id == viewId);
      if (view != null) {
        final nonEmptyName = view.name.isEmpty
            ? LocaleKeys.document_title_placeholder.tr()
            : view.name;
        result = result.replaceAll(RegExp(viewId), nonEmptyName);
      }
    }
    return result;
  }

  void _notifyUpdateSelectedViews() {
    final stateCopy = state;
    final selectedViews =
        allViews.where((view) => selectedViewIds.contains(view.id)).toList();
    emit(ChatInputControlState.updateSelectedViews(selectedViews));
    emit(stateCopy);
  }
}

@freezed
class ChatInputControlState with _$ChatInputControlState {
  const factory ChatInputControlState.loading() = _Loading;

  const factory ChatInputControlState.ready({
    required List<ViewPB> visibleViews,
    required int focusedViewIndex,
  }) = _Ready;

  const factory ChatInputControlState.updateSelectedViews(
    List<ViewPB> selectedViews,
  ) = _UpdateOneShot;
}
