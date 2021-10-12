import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app_flowy/workspace/domain/i_view.dart';

part 'view_edit_bloc.freezed.dart';

class ViewEditBloc extends Bloc<ViewEditEvent, ViewEditState> {
  final IView iViewImpl;

  ViewEditBloc({
    required this.iViewImpl,
  }) : super(ViewEditState.initial());

  @override
  Stream<ViewEditState> mapEventToState(ViewEditEvent event) async* {
    yield* event.map(initial: (_) async* {
      yield state;
    });
  }
}

@freezed
class ViewEditEvent with _$ViewEditEvent {
  const factory ViewEditEvent.initial() = Initial;
}

@freezed
class ViewEditState with _$ViewEditState {
  const factory ViewEditState({
    required bool isLoading,
    required Option<View> view,
    required Either<Unit, WorkspaceError> successOrFailure,
  }) = _ViewState;

  factory ViewEditState.initial() => ViewEditState(
        isLoading: false,
        view: none(),
        successOrFailure: left(unit),
      );
}
