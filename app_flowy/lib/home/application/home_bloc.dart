import 'package:app_flowy/home/domain/edit_context.dart';
import 'package:app_flowy/home/domain/page_context.dart';
import 'package:app_flowy/home/presentation/widgets/blank_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

part 'home_event.dart';
part 'home_state.dart';
part 'home_bloc.freezed.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeState.initial());

  @override
  Stream<HomeState> mapEventToState(
    HomeEvent event,
  ) async* {
    yield* event.map(
      setPage: (e) async* {
        yield state.copyWith(pageContext: e.context);
      },
      showLoading: (e) async* {
        yield state.copyWith(isLoading: e.isLoading);
      },
      setEditPannel: (e) async* {
        yield state.copyWith(editContext: some(e.editContext));
      },
      dismissEditPannel: (value) async* {
        yield state.copyWith(editContext: none());
      },
      showMenu: (e) async* {
        yield state.copyWith(showMenu: e.isShow);
      },
    );
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
