import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '_page_style_icon_bloc.freezed.dart';

class PageStyleIconBloc extends Bloc<PageStyleIconEvent, PageStyleIconState> {
  PageStyleIconBloc({
    required this.view,
  })  : _viewListener = ViewListener(viewId: view.id),
        super(PageStyleIconState.initial()) {
    on<PageStyleIconEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            add(
              PageStyleIconEvent.updateIcon(
                view.icon.value,
                false,
              ),
            );
            _viewListener?.start(
              onViewUpdated: (view) {
                add(
                  PageStyleIconEvent.updateIcon(
                    view.icon.value,
                    false,
                  ),
                );
              },
            );
          },
          updateIcon: (icon, shouldUpdateRemote) async {
            emit(
              state.copyWith(
                icon: icon,
              ),
            );
            if (shouldUpdateRemote && icon != null) {
              await ViewBackendService.updateViewIcon(
                viewId: view.id,
                viewIcon: icon,
              );
            }
          },
        );
      },
    );
  }

  final ViewPB view;
  final ViewListener? _viewListener;

  @override
  Future<void> close() {
    _viewListener?.stop();
    return super.close();
  }
}

@freezed
class PageStyleIconEvent with _$PageStyleIconEvent {
  const factory PageStyleIconEvent.initial() = Initial;
  const factory PageStyleIconEvent.updateIcon(
    String? icon,
    bool shouldUpdateRemote,
  ) = UpdateIconInner;
}

@freezed
class PageStyleIconState with _$PageStyleIconState {
  const factory PageStyleIconState({
    @Default(null) String? icon,
  }) = _PageStyleIconState;

  factory PageStyleIconState.initial() => const PageStyleIconState();
}
