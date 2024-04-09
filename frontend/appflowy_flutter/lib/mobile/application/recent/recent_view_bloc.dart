import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/document_listener.dart';
import 'package:appflowy/plugins/document/application/document_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'recent_view_bloc.freezed.dart';

class RecentViewBloc extends Bloc<RecentViewEvent, RecentViewState> {
  RecentViewBloc({
    required this.view,
  })  : _documentListener = DocumentListener(id: view.id),
        _viewListener = ViewListener(viewId: view.id),
        super(RecentViewState.initial()) {
    on<RecentViewEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _documentListener.start(
              onDocEventUpdate: (docEvent) async {
                final (coverType, coverValue) = await getCover();
                add(
                  RecentViewEvent.updateCover(
                    coverType,
                    coverValue,
                  ),
                );
              },
            );
            _viewListener.start(
              onViewUpdated: (view) {
                add(
                  RecentViewEvent.updateNameOrIcon(
                    view.name,
                    view.icon.value,
                  ),
                );
              },
            );
            final (coverType, coverValue) = await getCover();
            emit(
              state.copyWith(
                name: view.name,
                icon: view.icon.value,
                coverType: coverType,
                coverValue: coverValue,
              ),
            );
          },
          updateNameOrIcon: (name, icon) {
            emit(
              state.copyWith(
                name: name,
                icon: icon,
              ),
            );
          },
          updateCover: (coverType, coverValue) {
            emit(
              state.copyWith(
                coverType: coverType,
                coverValue: coverValue,
              ),
            );
          },
        );
      },
    );
  }

  final _service = DocumentService();
  final ViewPB view;
  final DocumentListener _documentListener;
  final ViewListener _viewListener;

  Future<(CoverType, String?)> getCover() async {
    final result = await _service.getDocument(viewId: view.id);
    final document = result.fold((s) => s.toDocument(), (f) => null);
    if (document != null) {
      final coverType = CoverType.fromString(
        document.root.attributes[DocumentHeaderBlockKeys.coverType],
      );
      final coverValue = document
          .root.attributes[DocumentHeaderBlockKeys.coverDetails] as String?;
      return (coverType, coverValue);
    }
    return (CoverType.none, null);
  }

  @override
  Future<void> close() async {
    await _documentListener.stop();
    await _viewListener.stop();
    return super.close();
  }
}

@freezed
class RecentViewEvent with _$RecentViewEvent {
  const factory RecentViewEvent.initial() = Initial;
  const factory RecentViewEvent.updateCover(
    CoverType coverType,
    String? coverValue,
  ) = UpdateCover;
  const factory RecentViewEvent.updateNameOrIcon(
    String name,
    String icon,
  ) = UpdateNameOrIcon;
}

@freezed
class RecentViewState with _$RecentViewState {
  const factory RecentViewState({
    required String name,
    required String icon,
    @Default(CoverType.none) CoverType coverType,
    @Default(null) String? coverValue,
  }) = _RecentViewState;

  factory RecentViewState.initial() =>
      const RecentViewState(name: '', icon: '');
}
