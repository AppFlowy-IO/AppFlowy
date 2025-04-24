import 'package:appflowy/startup/startup.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'view_ancestor_cache.dart';
part 'mobile_view_ancestors.freezed.dart';

class ViewAncestorBloc extends Bloc<ViewAncestorEvent, ViewAncestorState> {
  ViewAncestorBloc(String viewId) : super(ViewAncestorState.initial(viewId)) {
    _cache = getIt<ViewAncestorCache>();
    _dispatch();
  }

  late final ViewAncestorCache _cache;

  void _dispatch() {
    on<ViewAncestorEvent>(
      (event, emit) async {
        await event.map(
          initial: (e) async {
            final ancester = await _cache.getAncestor(
              state.viewId,
              onRefresh: (ancestor) {
                if (!emit.isDone) {
                  emit(state.copyWith(ancestor: ancestor, isLoading: false));
                }
              },
            );
            emit(state.copyWith(ancestor: ancester, isLoading: false));
          },
        );
      },
    );
    add(const ViewAncestorEvent.initial());
  }
}

@freezed
class ViewAncestorEvent with _$ViewAncestorEvent {
  const factory ViewAncestorEvent.initial() = Initial;
}

@freezed
class ViewAncestorState with _$ViewAncestorState {
  const factory ViewAncestorState({
    required ViewAncestor ancestor,
    required String viewId,
    @Default(true) bool isLoading,
  }) = _ViewAncestorState;

  factory ViewAncestorState.initial(String viewId) => ViewAncestorState(
        viewId: viewId,
        ancestor: ViewAncestor.empty(),
      );
}
