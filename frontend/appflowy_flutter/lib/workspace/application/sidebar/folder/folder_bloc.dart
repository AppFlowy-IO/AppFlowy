import 'dart:convert';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder_bloc.freezed.dart';

enum FolderSpaceType {
  favorite,
  private,
  public;

  ViewSectionPB get toViewSectionPB {
    switch (this) {
      case FolderSpaceType.private:
        return ViewSectionPB.Private;
      case FolderSpaceType.public:
        return ViewSectionPB.Public;
      case FolderSpaceType.favorite:
        throw UnimplementedError();
    }
  }
}

class FolderBloc extends Bloc<FolderEvent, FolderState> {
  FolderBloc({
    required FolderSpaceType type,
  }) : super(FolderState.initial(type)) {
    on<FolderEvent>((event, emit) async {
      await event.map(
        initial: (e) async {
          // fetch the expand status
          final isExpanded = await _getFolderExpandStatus();
          emit(state.copyWith(isExpanded: isExpanded));
        },
        expandOrUnExpand: (e) async {
          final isExpanded = e.isExpanded ?? !state.isExpanded;
          await _setFolderExpandStatus(isExpanded);
          emit(state.copyWith(isExpanded: isExpanded));
        },
      );
    });
  }

  Future<void> _setFolderExpandStatus(bool isExpanded) async {
    final result = await getIt<KeyValueStorage>().get(KVKeys.expandedViews);
    var map = {};
    if (result != null) {
      map = jsonDecode(result);
    }
    if (isExpanded) {
      // set expand status to true if it's not expanded
      map[state.type.name] = true;
    } else {
      // remove the expand status if it's expanded
      map.remove(state.type.name);
    }
    await getIt<KeyValueStorage>().set(KVKeys.expandedViews, jsonEncode(map));
  }

  Future<bool> _getFolderExpandStatus() async {
    return getIt<KeyValueStorage>().get(KVKeys.expandedViews).then((result) {
      if (result == null) {
        return true;
      }
      final map = jsonDecode(result);
      return map[state.type.name] ?? true;
    });
  }
}

@freezed
class FolderEvent with _$FolderEvent {
  const factory FolderEvent.initial() = Initial;
  const factory FolderEvent.expandOrUnExpand({
    bool? isExpanded,
  }) = ExpandOrUnExpand;
}

@freezed
class FolderState with _$FolderState {
  const factory FolderState({
    required FolderSpaceType type,
    required bool isExpanded,
  }) = _FolderState;

  factory FolderState.initial(
    FolderSpaceType type,
  ) =>
      FolderState(
        type: type,
        isExpanded: true,
      );
}
