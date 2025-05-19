import 'package:appflowy/features/shared_sidebar/data/share_pages_repository.dart';
import 'package:appflowy/features/shared_sidebar/models/shared_page.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shared_sidebar_bloc.freezed.dart';

class SharedSidebarBloc extends Bloc<SharedSidebarEvent, SharedSidebarState> {
  SharedSidebarBloc({required this.repository})
      : super(SharedSidebarState.initial()) {
    on<_Init>(_onInit);
    on<_SelectPage>(_onSelectPage);
    on<_Refresh>(_onRefresh);
  }

  final SharePagesRepository repository;

  Future<void> _onInit(
    _Init event,
    Emitter<SharedSidebarState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    final result = await repository.getSharedPages();
    result.fold(
      (pages) {
        emit(
          state.copyWith(
            sharedPages: pages,
            selectedPageId: pages.isNotEmpty ? pages.first.view.id : null,
            isLoading: false,
          ),
        );
      },
      (error) {
        emit(
          state.copyWith(
            errorMessage: error.msg,
            isLoading: false,
          ),
        );
      },
    );
  }

  void _onSelectPage(
    _SelectPage event,
    Emitter<SharedSidebarState> emit,
  ) {
    emit(state.copyWith(selectedPageId: event.pageId));
  }

  Future<void> _onRefresh(
    _Refresh event,
    Emitter<SharedSidebarState> emit,
  ) async {
    add(const SharedSidebarEvent.init());
  }
}

@freezed
class SharedSidebarEvent with _$SharedSidebarEvent {
  const factory SharedSidebarEvent.init() = _Init;
  const factory SharedSidebarEvent.selectPage({required String pageId}) =
      _SelectPage;
  const factory SharedSidebarEvent.refresh() = _Refresh;
}

@freezed
class SharedSidebarState with _$SharedSidebarState {
  const factory SharedSidebarState({
    @Default([]) SharedPages sharedPages,
    String? selectedPageId,
    @Default(false) bool isLoading,
    @Default('') String errorMessage,
  }) = _SharedSidebarState;

  const SharedSidebarState._();

  factory SharedSidebarState.initial() => const SharedSidebarState();
}
