import 'dart:async';

import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy/features/shared_section/data/share_pages_repository.dart';
import 'package:appflowy/features/shared_section/models/shared_page.dart';
import 'package:appflowy/features/shared_section/util/extensions.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shared_section_bloc.freezed.dart';

class SharedSectionBloc extends Bloc<SharedSectionEvent, SharedSectionState> {
  SharedSectionBloc({
    required this.repository,
    required this.workspaceId,
    this.enablePolling = false,
    this.pollingIntervalSeconds = 30,
  }) : super(SharedSectionState.initial()) {
    on<_Init>(_onInit);
    on<_Refresh>(_onRefresh);
    on<_UpdateSharedPages>(_onUpdateSharedPages);
  }

  final String workspaceId;

  // The repository to fetch the shared views.
  // If you need to test this bloc, you can add your own repository implementation.
  final SharePagesRepository repository;

  // Used to listen for shared view updates.
  late final FolderNotificationListener _folderNotificationListener;

  // Since the backend doesn't provide a way to listen for shared view updates (websocket with shared view updates is not implemented yet),
  // we need to poll the shared views periodically.
  final bool enablePolling;

  // The interval of polling the shared views.
  final int pollingIntervalSeconds;

  Timer? _pollingTimer;

  @override
  Future<void> close() async {
    await _folderNotificationListener.stop();
    _pollingTimer?.cancel();
    await super.close();
  }

  Future<void> _onInit(
    _Init event,
    Emitter<SharedSectionState> emit,
  ) async {
    _initFolderNotificationListener();
    _startPollingIfNeeded();

    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: '',
      ),
    );
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
    Emitter<SharedSectionState> emit,
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
    Emitter<SharedSectionState> emit,
  ) {
    emit(
      state.copyWith(
        sharedPages: event.sharedPages,
      ),
    );
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
              SharedSectionEvent.updateSharedPages(
                sharedPages: response.sharedPages,
              ),
            );
          }
        }
      },
    );
  }

  void _startPollingIfNeeded() {
    _pollingTimer?.cancel();
    if (enablePolling && pollingIntervalSeconds > 0) {
      _pollingTimer = Timer.periodic(
        Duration(seconds: pollingIntervalSeconds),
        (_) {
          add(const SharedSectionEvent.refresh());

          Log.debug('Polling shared views');
        },
      );
    }
  }
}

@freezed
class SharedSectionEvent with _$SharedSectionEvent {
  /// Initialize, it will create a folder notification listener to listen for shared view updates.
  /// Also, it will fetch the shared pages from the repository.
  const factory SharedSectionEvent.init() = _Init;

  /// Refresh, it will re-fetch the shared pages from the repository.
  const factory SharedSectionEvent.refresh() = _Refresh;

  /// Update the shared pages in the state.
  const factory SharedSectionEvent.updateSharedPages({
    required SharedPages sharedPages,
  }) = _UpdateSharedPages;
}

@freezed
class SharedSectionState with _$SharedSectionState {
  const factory SharedSectionState({
    @Default([]) SharedPages sharedPages,
    @Default(false) bool isLoading,
    @Default('') String errorMessage,
  }) = _SharedSectionState;

  const SharedSectionState._();

  factory SharedSectionState.initial() => const SharedSectionState();
}
