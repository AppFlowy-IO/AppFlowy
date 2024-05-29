import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'view_title_bloc.freezed.dart';

class ViewTitleBloc extends Bloc<ViewTitleEvent, ViewTitleState> {
  ViewTitleBloc({
    required this.view,
  })  : viewListener = ViewListener(viewId: view.id),
        super(ViewTitleState.initial()) {
    on<ViewTitleEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            emit(
              state.copyWith(
                name: view.name,
                icon: view.icon.value,
              ),
            );

            viewListener.start(
              onViewUpdated: (view) {
                add(
                  ViewTitleEvent.updateNameOrIcon(
                    view.name,
                    view.icon.value,
                  ),
                );
              },
            );
          },
          updateNameOrIcon: (name, icon) async {
            emit(
              state.copyWith(
                name: name,
                icon: icon,
              ),
            );
          },
        );
      },
    );
  }

  final ViewPB view;
  final ViewListener viewListener;

  @override
  Future<void> close() {
    viewListener.stop();
    return super.close();
  }
}

@freezed
class ViewTitleEvent with _$ViewTitleEvent {
  const factory ViewTitleEvent.initial() = Initial;
  const factory ViewTitleEvent.updateNameOrIcon(String name, String icon) =
      UpdateNameOrIcon;
}

@freezed
class ViewTitleState with _$ViewTitleState {
  const factory ViewTitleState({
    required String name,
    required String icon,
  }) = _ViewTitleState;

  factory ViewTitleState.initial() => const ViewTitleState(name: '', icon: '');
}
