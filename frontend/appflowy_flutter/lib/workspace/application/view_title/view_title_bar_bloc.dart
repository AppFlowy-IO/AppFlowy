import 'package:appflowy/plugins/trash/application/prelude.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'view_title_bar_bloc.freezed.dart';

class ViewTitleBarBloc extends Bloc<ViewTitleBarEvent, ViewTitleBarState> {
  ViewTitleBarBloc({
    required this.view,
  }) : super(ViewTitleBarState.initial()) {
    viewListener = ViewListener(viewId: view.id)
      ..start(
        onViewChildViewsUpdated: (_) => add(const ViewTitleBarEvent.reload()),
      );
    trashListener = TrashListener()
      ..start(
        trashUpdated: (trashOrFailed) {
          final trash = trashOrFailed.toNullable();
          if (trash != null) {
            add(ViewTitleBarEvent.trashUpdated(trash: trash));
          }
        },
      );

    on<ViewTitleBarEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            add(const ViewTitleBarEvent.reload());
          },
          reload: () async {
            final List<ViewPB> ancestors =
                await ViewBackendService.getViewAncestors(view.id).fold(
              (s) => s.items,
              (f) => [],
            );

            final trash =
                (await TrashService().readTrash()).toNullable()?.items;
            final isDeleted = trash?.any((t) => t.id == view.id) ?? false;

            emit(state.copyWith(ancestors: ancestors, isDeleted: isDeleted));
          },
          trashUpdated: (trash) {
            if (trash.any((t) => t.id == view.id)) {
              emit(state.copyWith(isDeleted: true));
            }
          },
        );
      },
    );
  }

  final ViewPB view;
  late final ViewListener viewListener;
  late final TrashListener trashListener;

  @override
  Future<void> close() {
    trashListener.close();
    viewListener.stop();
    return super.close();
  }
}

@freezed
class ViewTitleBarEvent with _$ViewTitleBarEvent {
  const factory ViewTitleBarEvent.initial() = Initial;
  const factory ViewTitleBarEvent.reload() = Reload;
  const factory ViewTitleBarEvent.trashUpdated({
    required List<TrashPB> trash,
  }) = TrashUpdated;
}

@freezed
class ViewTitleBarState with _$ViewTitleBarState {
  const factory ViewTitleBarState({
    required List<ViewPB> ancestors,
    @Default(false) bool isDeleted,
  }) = _ViewTitleBarState;

  factory ViewTitleBarState.initial() => const ViewTitleBarState(ancestors: []);
}
