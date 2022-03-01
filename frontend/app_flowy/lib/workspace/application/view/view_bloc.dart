import 'package:app_flowy/workspace/application/view/view_listener.dart';
import 'package:app_flowy/workspace/application/view/view_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'view_bloc.freezed.dart';

class ViewBloc extends Bloc<ViewEvent, ViewState> {
  final ViewService service;
  final ViewListener listener;
  final View view;

  ViewBloc({
    required this.view,
    required this.service,
    required this.listener,
  }) : super(ViewState.init(view)) {
    on<ViewEvent>((event, emit) async {
      await event.map(
        initial: (e) {
          // TODO: Listener can be refactored to a stream.
          listener.updatedNotifier.addPublishListener((result) {
            // emit.forEach(stream, onData: onData)
            add(ViewEvent.viewDidUpdate(result));
          });
          listener.start();
          emit(state);
        },
        setIsEditing: (e) {
          emit(state.copyWith(isEditing: e.isEditing));
        },
        viewDidUpdate: (e) {
          e.result.fold(
            (view) => emit(state.copyWith(view: view, successOrFailure: left(unit))),
            (error) => emit(state.copyWith(successOrFailure: right(error))),
          );
        },
        rename: (e) async {
          final result = await service.updateView(viewId: view.id, name: e.newName);
          emit(
            result.fold(
              (l) => state.copyWith(successOrFailure: left(unit)),
              (error) => state.copyWith(successOrFailure: right(error)),
            ),
          );
        },
        delete: (e) async {
          final result = await service.delete(viewId: view.id);
          emit(
            result.fold(
              (l) => state.copyWith(successOrFailure: left(unit)),
              (error) => state.copyWith(successOrFailure: right(error)),
            ),
          );
        },
        duplicate: (e) async {
          final result = await service.duplicate(viewId: view.id);
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
    await listener.close();
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
  const factory ViewEvent.viewDidUpdate(Either<View, FlowyError> result) = ViewDidUpdate;
}

@freezed
class ViewState with _$ViewState {
  const factory ViewState({
    required View view,
    required bool isEditing,
    required Either<Unit, FlowyError> successOrFailure,
  }) = _ViewState;

  factory ViewState.init(View view) => ViewState(
        view: view,
        isEditing: false,
        successOrFailure: left(unit),
      );
}
