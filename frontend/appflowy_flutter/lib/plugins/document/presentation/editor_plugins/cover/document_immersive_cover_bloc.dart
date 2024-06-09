import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_immersive_cover_bloc.freezed.dart';

class DocumentImmersiveCoverBloc
    extends Bloc<DocumentImmersiveCoverEvent, DocumentImmersiveCoverState> {
  DocumentImmersiveCoverBloc({
    required this.view,
  })  : _viewListener = ViewListener(viewId: view.id),
        super(DocumentImmersiveCoverState.initial()) {
    on<DocumentImmersiveCoverEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            add(
              DocumentImmersiveCoverEvent.updateCoverAndIcon(
                view.cover,
                view.icon.value,
                view.name,
              ),
            );
            _viewListener?.start(
              onViewUpdated: (view) {
                add(
                  DocumentImmersiveCoverEvent.updateCoverAndIcon(
                    view.cover,
                    view.icon.value,
                    view.name,
                  ),
                );
              },
            );
          },
          updateCoverAndIcon: (cover, icon, name) {
            emit(
              state.copyWith(
                icon: icon,
                cover: cover ?? state.cover,
                name: name ?? state.name,
              ),
            );
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
class DocumentImmersiveCoverEvent with _$DocumentImmersiveCoverEvent {
  const factory DocumentImmersiveCoverEvent.initial() = Initial;
  const factory DocumentImmersiveCoverEvent.updateCoverAndIcon(
    PageStyleCover? cover,
    String? icon,
    String? name,
  ) = UpdateCoverAndIcon;
}

@freezed
class DocumentImmersiveCoverState with _$DocumentImmersiveCoverState {
  const factory DocumentImmersiveCoverState({
    @Default(null) String? icon,
    required PageStyleCover cover,
    @Default('') String name,
  }) = _DocumentImmersiveCoverState;

  factory DocumentImmersiveCoverState.initial() => DocumentImmersiveCoverState(
        cover: PageStyleCover.none(),
      );
}
