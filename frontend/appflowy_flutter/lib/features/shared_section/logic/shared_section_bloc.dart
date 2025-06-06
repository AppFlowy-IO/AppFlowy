import 'dart:async';

import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy/features/shared_section/data/repositories/shared_pages_repository.dart';
import 'package:appflowy/features/shared_section/logic/shared_section_event.dart';
import 'package:appflowy/features/shared_section/logic/shared_section_state.dart';
import 'package:appflowy/features/util/extensions.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'shared_section_event.dart';
export 'shared_section_state.dart';

class SharedSectionBloc extends Bloc<SharedSectionEvent, SharedSectionState> {
  SharedSectionBloc({
    required this.repository,
    required this.workspaceId,
    this.enablePolling = false,
    this.pollingIntervalSeconds = 30,
  }) : super(SharedSectionState.initial()) {
    on<SharedSectionInitEvent>(_onInit);
    on<SharedSectionRefreshEvent>(_onRefresh);
    on<SharedSectionUpdateSharedPagesEvent>(_onUpdateSharedPages);
    on<SharedSectionToggleExpandedEvent>(_onToggleExpanded);
    on<SharedSectionLeaveSharedPageEvent>(_onLeaveSharedPage);
  }

  final String workspaceId;

  // The repository to fetch the shared views.
  // If you need to test this bloc, you can add your own repository implementation.
  final SharedPagesRepository repository;

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
    SharedSectionInitEvent event,
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
    SharedSectionRefreshEvent event,
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
    SharedSectionUpdateSharedPagesEvent event,
    Emitter<SharedSectionState> emit,
  ) {
    emit(
      state.copyWith(
        sharedPages: event.sharedPages,
      ),
    );
  }

  void _onToggleExpanded(
    SharedSectionToggleExpandedEvent event,
    Emitter<SharedSectionState> emit,
  ) {
    emit(
      state.copyWith(
        isExpanded: !state.isExpanded,
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

  void _onLeaveSharedPage(
    SharedSectionLeaveSharedPageEvent event,
    Emitter<SharedSectionState> emit,
  ) async {
    final result = await repository.leaveSharedPage(event.pageId);
    result.fold(
      (success) {
        add(const SharedSectionEvent.refresh());
      },
      (error) {
        emit(state.copyWith(errorMessage: error.msg));
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
