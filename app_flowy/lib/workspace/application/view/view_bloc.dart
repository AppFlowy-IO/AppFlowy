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
  }) : super(ViewState.initial());

  @override
  Stream<ViewState> mapEventToState(ViewEvent event) async* {
    yield* event.map(initial: (_) async* {
      yield state;
    });
  }
}

@freezed
abstract class ViewEvent with _$ViewEvent {
  const factory ViewEvent.initial() = Initial;
}

@freezed
abstract class ViewState implements _$ViewState {
  const factory ViewState({
    required bool isLoading,
    required Option<View> view,
    required Either<Unit, WorkspaceError> successOrFailure,
  }) = _ViewState;

  factory ViewState.initial() => ViewState(
        isLoading: false,
        view: none(),
        successOrFailure: left(unit),
      );
}
