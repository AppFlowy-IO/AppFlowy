import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'view_title_bar_bloc.freezed.dart';

class ViewTitleBarBloc extends Bloc<ViewTitleBarEvent, ViewTitleBarState> {
  ViewTitleBarBloc({
    required this.view,
  }) : super(ViewTitleBarState.initial()) {
    on<ViewTitleBarEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            add(const ViewTitleBarEvent.reload());

            viewListener = ViewListener(
              viewId: view.id,
            )..start(
                onViewUpdated: (p0) {
                  add(const ViewTitleBarEvent.reload());
                },
              );
          },
          reload: () async {
            final List<ViewPB> ancestors =
                await ViewBackendService.getViewAncestors(view.id).fold(
              (s) => s.items,
              (f) => [],
            );
            emit(state.copyWith(ancestors: ancestors));
          },
        );
      },
    );
  }

  final ViewPB view;
  late final ViewListener viewListener;

  @override
  Future<void> close() {
    viewListener.stop();
    return super.close();
  }
}

@freezed
class ViewTitleBarEvent with _$ViewTitleBarEvent {
  const factory ViewTitleBarEvent.initial() = Initial;
  const factory ViewTitleBarEvent.reload() = Reload;
}

@freezed
class ViewTitleBarState with _$ViewTitleBarState {
  const factory ViewTitleBarState({
    required List<ViewPB> ancestors,
  }) = _ViewTitleBarState;

  factory ViewTitleBarState.initial() => const ViewTitleBarState(ancestors: []);
}
