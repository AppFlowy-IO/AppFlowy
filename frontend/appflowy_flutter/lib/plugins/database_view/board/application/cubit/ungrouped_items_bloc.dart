import 'package:appflowy/plugins/database_view/board/application/group_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ungrouped_items_bloc.freezed.dart';

class UngroupedItemsBloc
    extends Bloc<UngroupedItemsEvent, UngroupedItemsState> {
  GroupController? _controller;

  UngroupedItemsBloc() : super(UngroupedItemsState()) {
    on<UngroupedItemsEvent>(
      (event, emit) {
        event.when(
          initial: () {},
          initController: (controller) {
            debugPrint("REACHED HERE!!!!");
            _controller = controller;
            _controller!.groupNotifier.addListener(_onGroupChanged);
          },
          updateState: () {
            emit(UngroupedItemsState());
          },
        );
      },
    );
  }

  void _onGroupChanged() {
    add(const UngroupedItemsEvent.updateState());
  }
}

@freezed
class UngroupedItemsEvent with _$UngroupedItemsEvent {
  const factory UngroupedItemsEvent.initial() = _Initial;

  const factory UngroupedItemsEvent.updateState() = _UpdateState;

  const factory UngroupedItemsEvent.initController({
    required GroupController controller,
  }) = _InitController;
}

class UngroupedItemsState {
  UngroupedItemsState();
}
