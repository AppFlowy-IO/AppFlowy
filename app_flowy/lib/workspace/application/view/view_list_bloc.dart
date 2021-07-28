import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

part 'view_list_bloc.freezed.dart';

class ViewListBloc extends Bloc<ViewListEvent, ViewListState> {
  final List<View> views;
  ViewListBloc({required this.views}) : super(ViewListState.initial(views));

  @override
  Stream<ViewListState> mapEventToState(ViewListEvent event) async* {
    yield* event.map(
      initial: (s) async* {
        yield ViewListState.initial(s.views);
      },
      openView: (s) async* {
        yield state.copyWith(selectedView: some(s.view.id));
      },
    );
  }
}

@freezed
class ViewListEvent with _$ViewListEvent {
  const factory ViewListEvent.initial(List<View> views) = Initial;
  const factory ViewListEvent.openView(View view) = OpenView;
}

@freezed
abstract class ViewListState implements _$ViewListState {
  const factory ViewListState({
    required bool isLoading,
    required Option<String> selectedView,
    required Option<List<View>> views,
  }) = _ViewListState;

  factory ViewListState.initial(List<View> views) => ViewListState(
        isLoading: false,
        selectedView: none(),
        views: some(views),
      );
}
