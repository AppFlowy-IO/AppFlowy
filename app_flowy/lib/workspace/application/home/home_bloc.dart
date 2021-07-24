import 'package:app_flowy/workspace/domain/edit_context.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
part 'home_bloc.freezed.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeState.initial());

  @override
  Stream<HomeState> mapEventToState(
    HomeEvent event,
  ) async* {
    yield* event.map(
      showLoading: (e) async* {
        yield state.copyWith(isLoading: e.isLoading);
      },
      setEditPannel: (e) async* {
        yield state.copyWith(editContext: some(e.editContext));
      },
      dismissEditPannel: (value) async* {
        yield state.copyWith(editContext: none());
      },
      forceCollapse: (e) async* {
        yield state.copyWith(forceCollapse: e.forceCollapse);
      },
    );
  }

  @override
  Future<void> close() {
    return super.close();
  }
}

@freezed
abstract class HomeEvent with _$HomeEvent {
  const factory HomeEvent.showLoading(bool isLoading) = _ShowLoading;
  const factory HomeEvent.forceCollapse(bool forceCollapse) = _ForceCollapse;
  const factory HomeEvent.setEditPannel(EditPannelContext editContext) =
      _ShowEditPannel;
  const factory HomeEvent.dismissEditPannel() = _DismissEditPannel;
}

@freezed
abstract class HomeState implements _$HomeState {
  const factory HomeState({
    required bool isLoading,
    required bool forceCollapse,
    required Option<EditPannelContext> editContext,
  }) = _HomeState;

  factory HomeState.initial() => HomeState(
        isLoading: false,
        forceCollapse: false,
        editContext: none(),
      );
}
