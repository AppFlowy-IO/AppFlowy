import 'dart:async';

import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'view_lock_status_bloc.freezed.dart';

class ViewLockStatusBloc
    extends Bloc<ViewLockStatusEvent, ViewLockStatusState> {
  ViewLockStatusBloc({
    required this.view,
  })  : viewBackendSvc = ViewBackendService(),
        listener = ViewListener(viewId: view.id),
        super(ViewLockStatusState.init(view)) {
    on<ViewLockStatusEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            listener.start(
              onViewUpdated: (view) async {
                add(ViewLockStatusEvent.updateLockStatus(view.isLocked));
              },
            );

            final latestView = await ViewBackendService.getView(view.id);
            latestView.fold(
              (view) => emit(
                state.copyWith(
                  view: view,
                  isLocked: view.isLocked,
                ),
              ),
              (_) => emit(
                state.copyWith(
                  view: view,
                  isLocked: false,
                ),
              ),
            );
          },
          lock: () async {
            final result = await ViewBackendService.lockView(view.id);
            final isLocked = result.fold(
              (_) => true,
              (_) => false,
            );
            add(ViewLockStatusEvent.updateLockStatus(isLocked));
          },
          unlock: () async {
            final result = await ViewBackendService.unlockView(view.id);
            final isLocked = result.fold(
              (_) => false,
              (_) => true,
            );
            add(ViewLockStatusEvent.updateLockStatus(isLocked));
          },
          updateLockStatus: (isLocked) async {
            emit(state.copyWith(isLocked: isLocked));
          },
        );
      },
    );
  }

  final ViewPB view;
  final ViewBackendService viewBackendSvc;
  final ViewListener listener;

  @override
  Future<void> close() async {
    await listener.stop();

    return super.close();
  }
}

@freezed
class ViewLockStatusEvent with _$ViewLockStatusEvent {
  const factory ViewLockStatusEvent.initial() = Initial;

  const factory ViewLockStatusEvent.lock() = Lock;
  const factory ViewLockStatusEvent.unlock() = Unlock;
  const factory ViewLockStatusEvent.updateLockStatus(bool isLocked) =
      UpdateLockStatus;
}

@freezed
class ViewLockStatusState with _$ViewLockStatusState {
  const factory ViewLockStatusState({
    required ViewPB view,
    required bool isLocked,
  }) = _ViewLockStatusState;

  factory ViewLockStatusState.init(ViewPB view) => ViewLockStatusState(
        view: view,
        isLocked: false,
      );
}
