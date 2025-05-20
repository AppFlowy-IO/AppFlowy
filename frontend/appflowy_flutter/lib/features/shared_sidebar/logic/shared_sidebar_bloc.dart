import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy/features/shared_sidebar/data/share_pages_repository.dart';
import 'package:appflowy/features/shared_sidebar/models/shared_page.dart';
import 'package:appflowy/features/shared_sidebar/util/extensions.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shared_sidebar_bloc.freezed.dart';

class SharedSidebarBloc extends Bloc<SharedSidebarEvent, SharedSidebarState> {
  SharedSidebarBloc({
    required this.repository,
    required this.workspaceId,
  }) : super(SharedSidebarState.initial()) {
    on<_Init>(_onInit);
    on<_Refresh>(_onRefresh);
    on<_UpdateSharedPages>(_onUpdateSharedPages);
  }

  final String workspaceId;
  final SharePagesRepository repository;
  late final FolderNotificationListener _folderNotificationListener;

  @override
  Future<void> close() async {
    await _folderNotificationListener.stop();

    await super.close();
  }

  Future<void> _onInit(
    _Init event,
    Emitter<SharedSidebarState> emit,
  ) async {
    _initFolderNotificationListener();
    
    emit(state.copyWith(isLoading: true, errorMessage: '',),);
    
    final result = await repository.getSharedPages();
    
    result.fold(
      (pages) {
        emit(
          state.copyWith(
            sharedPages: pages,
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

  Future<void> _onRefresh(
    _Refresh event,
    Emitter<SharedSidebarState> emit,
  ) async {
    final result = await repository.getSharedPages();
    
    result.fold(
      (pages) {
        emit(
          state.copyWith(
            sharedPages: pages,
            
          ),
        );
      },
      (error) {
        emit(
          state.copyWith(
            errorMessage: error.msg,
            
          ),
        );
      },
    );
  }

  void _onUpdateSharedPages(
    _UpdateSharedPages event,
    Emitter<SharedSidebarState> emit,
  ) {
    emit(state.copyWith(sharedPages: event.sharedPages));
  }

  void _initFolderNotificationListener() {
    _folderNotificationListener = FolderNotificationListener(
      objectId: workspaceId,
      handler: (notification, result) {
        if (notification == FolderNotification.DidUpdateSharedViews) {
          final response = result.fold(
            (payload) {
              final repeatedSharedViews =
                  RepeatedSharedViewResponsePB.fromBuffer(payload);
              return repeatedSharedViews;
            },
            (error) => null,
          );
          if (response != null) {
            add(
              SharedSidebarEvent.updateSharedPages(
                sharedPages: response.sharedPages,
              ),
            );
          }
        }
      },
    );
  }
}

@freezed
class SharedSidebarEvent with _$SharedSidebarEvent {
  /// Initialize, it will create a folder notification listener to listen for shared view updates.
  /// Also, it will fetch the shared pages from the repository.
  const factory SharedSidebarEvent.init() = _Init;

  /// Refresh, it will re-fetch the shared pages from the repository.
  const factory SharedSidebarEvent.refresh() = _Refresh;

  /// Update the shared pages in the state.
  const factory SharedSidebarEvent.updateSharedPages({
    required SharedPages sharedPages,
  }) = _UpdateSharedPages;
}

@freezed
class SharedSidebarState with _$SharedSidebarState {
  const factory SharedSidebarState({
    @Default([]) SharedPages sharedPages,
    @Default(false) bool isLoading,
    @Default('') String errorMessage,
  }) = _SharedSidebarState;

  const SharedSidebarState._();

  factory SharedSidebarState.initial() => const SharedSidebarState();
}
