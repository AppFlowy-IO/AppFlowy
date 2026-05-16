import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'space_search_bloc.freezed.dart';

class SpaceSearchBloc extends Bloc<SpaceSearchEvent, SpaceSearchState> {
  SpaceSearchBloc() : super(SpaceSearchState.initial()) {
    on<SpaceSearchEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _allViews = await ViewBackendService.getAllViews().fold(
              (s) => s.items,
              (_) => <ViewPB>[],
            );
          },
          search: (query) {
            if (query.isEmpty) {
              emit(
                state.copyWith(
                  queryResults: null,
                ),
              );
            } else {
              final queryResults = _allViews.where(
                (view) => view.name.toLowerCase().contains(query.toLowerCase()),
              );
              emit(
                state.copyWith(
                  queryResults: queryResults.toList(),
                ),
              );
            }
          },
        );
      },
    );
  }

  late final List<ViewPB> _allViews;
}

@freezed
class SpaceSearchEvent with _$SpaceSearchEvent {
  const factory SpaceSearchEvent.initial() = _Initial;
  const factory SpaceSearchEvent.search(String query) = _Search;
}

@freezed
class SpaceSearchState with _$SpaceSearchState {
  const factory SpaceSearchState({
    List<ViewPB>? queryResults,
  }) = _SpaceSearchState;

  factory SpaceSearchState.initial() => const SpaceSearchState();
}
