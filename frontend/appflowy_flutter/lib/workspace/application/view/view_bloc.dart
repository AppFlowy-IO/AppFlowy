import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'view_bloc.freezed.dart';

class ViewBloc extends Bloc<ViewEvent, ViewState> {
  final ViewBackendService viewBackendSvc;
  final ViewListener listener;
  final ViewPB view;

  ViewBloc({
    required this.view,
  })  : viewBackendSvc = ViewBackendService(),
        listener = ViewListener(view: view),
        super(ViewState.init(view)) {
    on<ViewEvent>((event, emit) async {
      await event.map(
        initial: (e) {
          listener.start(
            onViewUpdated: (result) {
              add(ViewEvent.viewDidUpdate(result));
            },
          );
          emit(state);
        },
        setIsEditing: (e) {
          emit(state.copyWith(isEditing: e.isEditing));
        },
        viewDidUpdate: (e) {
          e.result.fold(
            (view) => emit(
              state.copyWith(view: view, successOrFailure: left(unit)),
            ),
            (error) => emit(
              state.copyWith(successOrFailure: right(error)),
            ),
          );
        },
        rename: (e) async {
          final result = await ViewBackendService.updateView(
            viewId: view.id,
            name: e.newName,
          );
          emit(
            result.fold(
              (l) => state.copyWith(successOrFailure: left(unit)),
              (error) => state.copyWith(successOrFailure: right(error)),
            ),
          );
        },
        delete: (e) async {
          final result = await ViewBackendService.delete(viewId: view.id);
          emit(
            result.fold(
              (l) => state.copyWith(successOrFailure: left(unit)),
              (error) => state.copyWith(successOrFailure: right(error)),
            ),
          );
        },
        duplicate: (e) async {
          final result = await ViewBackendService.duplicate(view: view);
          emit(
            result.fold(
              (l) => state.copyWith(successOrFailure: left(unit)),
              (error) => state.copyWith(successOrFailure: right(error)),
            ),
          );
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await listener.stop();
    return super.close();
  }
}

@freezed
class ViewEvent with _$ViewEvent {
  const factory ViewEvent.initial() = Initial;
  const factory ViewEvent.setIsEditing(bool isEditing) = SetEditing;
  const factory ViewEvent.rename(String newName) = Rename;
  const factory ViewEvent.delete() = Delete;
  const factory ViewEvent.duplicate() = Duplicate;
  const factory ViewEvent.viewDidUpdate(Either<ViewPB, FlowyError> result) =
      ViewDidUpdate;
}

@freezed
class ViewState with _$ViewState {
  const factory ViewState({
    required ViewPB view,
    required bool isEditing,
    required Either<Unit, FlowyError> successOrFailure,
  }) = _ViewState;

  factory ViewState.init(ViewPB view) => ViewState(
        view: view,
        isEditing: false,
        successOrFailure: left(unit),
      );
}
