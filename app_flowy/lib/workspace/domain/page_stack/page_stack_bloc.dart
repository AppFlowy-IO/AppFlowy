import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/blank_page.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'page_stack_bloc.freezed.dart';

class PageStackBloc extends Bloc<PageStackEvent, PageStackState> {
  PageStackBloc() : super(PageStackState.initial());

  @override
  Stream<PageStackState> mapEventToState(
    PageStackEvent event,
  ) async* {
    yield* event.map(setContext: (NewPageContext value) async* {
      yield state.copyWith(pageContext: value.newContext);
    });
  }
}

@freezed
abstract class PageStackEvent with _$PageStackEvent {
  const factory PageStackEvent.setContext(HomeStackContext newContext) =
      NewPageContext;
}

@freezed
abstract class PageStackState implements _$PageStackState {
  const factory PageStackState({
    required HomeStackContext pageContext,
  }) = _PageStackState;

  factory PageStackState.initial() => const PageStackState(
        pageContext: BlankPageContext(),
      );
}
