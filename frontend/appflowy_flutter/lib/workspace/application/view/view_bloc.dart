import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'view_bloc.freezed.dart';

class ViewBloc extends Bloc<ViewEvent, ViewState> {
  final ViewService service;
  final ViewListener listener;
  final ViewPB view;

  ViewBloc({
    required this.view,
  })  : service = ViewService(),
        listener = ViewListener(view: view),
        super(ViewState.init(view)) {
    on<ViewEvent>((final event, final emit) async {
      await event.map(
        initial: (final e) {
          listener.start(
            onViewUpdated: (final result) {
              add(ViewEvent.viewDidUpdate(result));
            },
          );
          emit(state);
        },
        setIsEditing: (final e) {
          emit(state.copyWith(isEditing: e.isEditing));
        },
        viewDidUpdate: (final e) {
          e.result.fold(
            (final view) => emit(
              state.copyWith(view: view, successOrFailure: left(unit)),
            ),
            (final error) => emit(
              state.copyWith(successOrFailure: right(error)),
            ),
          );
        },
        rename: (final e) async {
          final result = await service.updateView(
            viewId: view.id,
            name: e.newName,
          );
          emit(
            result.fold(
              (final l) => state.copyWith(successOrFailure: left(unit)),
              (final error) => state.copyWith(successOrFailure: right(error)),
            ),
          );
        },
        delete: (final e) async {
          final result = await service.delete(viewId: view.id);
          emit(
            result.fold(
              (final l) => state.copyWith(successOrFailure: left(unit)),
              (final error) => state.copyWith(successOrFailure: right(error)),
            ),
          );
        },
        duplicate: (final e) async {
          final result = await service.duplicate(view: view);
          emit(
            result.fold(
              (final l) => state.copyWith(successOrFailure: left(unit)),
              (final error) => state.copyWith(successOrFailure: right(error)),
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
  const factory ViewEvent.setIsEditing(final bool isEditing) = SetEditing;
  const factory ViewEvent.rename(final String newName) = Rename;
  const factory ViewEvent.delete() = Delete;
  const factory ViewEvent.duplicate() = Duplicate;
  const factory ViewEvent.viewDidUpdate(final Either<ViewPB, FlowyError> result) =
      ViewDidUpdate;
}

@freezed
class ViewState with _$ViewState {
  const factory ViewState({
    required final ViewPB view,
    required final bool isEditing,
    required final Either<Unit, FlowyError> successOrFailure,
  }) = _ViewState;

  factory ViewState.init(final ViewPB view) => ViewState(
        view: view,
        isEditing: false,
        successOrFailure: left(unit),
      );
}
