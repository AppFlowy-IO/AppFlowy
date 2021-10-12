import 'package:app_flowy/workspace/domain/view_edit.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app_flowy/workspace/domain/i_view.dart';

part 'view_bloc.freezed.dart';

class ViewBloc extends Bloc<ViewEvent, ViewState> {
  final IView iViewImpl;

  ViewBloc({
    required this.iViewImpl,
  }) : super(ViewState.initial(iViewImpl.view));

  @override
  Stream<ViewState> mapEventToState(ViewEvent event) async* {
    yield* event.map(
      setIsSelected: (e) async* {
        yield state.copyWith(isSelected: e.isSelected);
      },
      setIsEditing: (e) async* {
        yield state.copyWith(isEditing: e.isEditing);
      },
      setAction: (e) async* {
        yield state.copyWith(action: e.action);
      },
    );
  }
}

@freezed
class ViewEvent with _$ViewEvent {
  const factory ViewEvent.setIsSelected(bool isSelected) = SetSelected;
  const factory ViewEvent.setIsEditing(bool isEditing) = SetEditing;
  const factory ViewEvent.setAction(Option<ViewAction> action) = SetAction;
}

@freezed
class ViewState with _$ViewState {
  const factory ViewState({
    required View view,
    required bool isSelected,
    required bool isEditing,
    required Option<ViewAction> action,
    required Either<Unit, WorkspaceError> successOrFailure,
  }) = _ViewState;

  factory ViewState.initial(View view) => ViewState(
        view: view,
        isSelected: false,
        isEditing: false,
        action: none(),
        successOrFailure: left(unit),
      );
}
