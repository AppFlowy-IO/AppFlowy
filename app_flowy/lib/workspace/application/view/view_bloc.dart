import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app_flowy/workspace/domain/i_view.dart';

part 'view_bloc.freezed.dart';

class ViewBloc extends Bloc<ViewEvent, ViewState> {
  final IView iViewImpl;
  final IViewListener listener;

  ViewBloc({
    required this.iViewImpl,
    required this.listener,
  }) : super(ViewState.init(iViewImpl.view));

  @override
  Stream<ViewState> mapEventToState(ViewEvent event) async* {
    yield* event.map(initial: (e) async* {
      listener.start(updatedCallback: (result) => add(ViewEvent.viewDidUpdate(result)));
      yield state;
    }, setIsEditing: (e) async* {
      yield state.copyWith(isEditing: e.isEditing);
    }, viewDidUpdate: (e) async* {
      yield* _handleViewDidUpdate(e.result);
    }, rename: (e) async* {
      final result = await iViewImpl.rename(e.newName);
      yield result.fold(
        (l) => state.copyWith(successOrFailure: left(unit)),
        (error) => state.copyWith(successOrFailure: right(error)),
      );
    }, delete: (e) async* {
      final result = await iViewImpl.delete();
      yield result.fold(
        (l) => state.copyWith(successOrFailure: left(unit)),
        (error) => state.copyWith(successOrFailure: right(error)),
      );
    });
  }

  Stream<ViewState> _handleViewDidUpdate(Either<View, WorkspaceError> result) async* {
    yield result.fold(
      (view) => state.copyWith(view: view, successOrFailure: left(unit)),
      (error) => state.copyWith(successOrFailure: right(error)),
    );
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
  const factory ViewEvent.viewDidUpdate(Either<View, WorkspaceError> result) = ViewDidUpdate;
}

@freezed
class ViewState with _$ViewState {
  const factory ViewState({
    required View view,
    required bool isEditing,
    required Either<Unit, WorkspaceError> successOrFailure,
  }) = _ViewState;

  factory ViewState.init(View view) => ViewState(
        view: view,
        isEditing: false,
        successOrFailure: left(unit),
      );
}
