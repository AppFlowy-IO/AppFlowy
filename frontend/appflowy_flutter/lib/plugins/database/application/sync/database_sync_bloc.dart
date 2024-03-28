import 'dart:async';

import 'package:appflowy/plugins/database/application/sync/database_sync_state_listener.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'database_sync_bloc.freezed.dart';

class DatabaseSyncBloc extends Bloc<DatabaseSyncEvent, DatabaseSyncBlocState> {
  DatabaseSyncBloc({
    required this.view,
  })  : _syncStateListener = DatabaseSyncStateListener(id: view.id),
        super(DatabaseSyncBlocState.initial()) {
    on<DatabaseSyncEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            final userProfile = await getIt<AuthService>().getUser().then(
                  (result) => result.fold(
                    (l) => l,
                    (r) => null,
                  ),
                );
            emit(
              state.copyWith(
                shouldShowIndicator:
                    userProfile?.authenticator != AuthenticatorPB.Local,
              ),
            );
            _syncStateListener.start(
              didReceiveSyncState: (syncState) {
                if (!isClosed) {
                  add(DatabaseSyncEvent.syncStateChanged(syncState));
                }
              },
            );

            final isNetworkConnected = await _connectivity
                .checkConnectivity()
                .then((value) => value != ConnectivityResult.none);
            emit(state.copyWith(isNetworkConnected: isNetworkConnected));

            connectivityStream =
                _connectivity.onConnectivityChanged.listen((result) {
              if (!isClosed) {
                emit(
                  state.copyWith(
                    isNetworkConnected: result != ConnectivityResult.none,
                  ),
                );
              }
            });
          },
          syncStateChanged: (syncState) {
            emit(state.copyWith(syncState: syncState.value));
          },
        );
      },
    );
  }

  final ViewPB view;
  final DatabaseSyncStateListener _syncStateListener;
  final _connectivity = Connectivity();

  StreamSubscription? connectivityStream;

  @override
  Future<void> close() async {
    await connectivityStream?.cancel();
    await _syncStateListener.stop();
    return super.close();
  }
}

@freezed
class DatabaseSyncEvent with _$DatabaseSyncEvent {
  const factory DatabaseSyncEvent.initial() = Initial;
  const factory DatabaseSyncEvent.syncStateChanged(
    DatabaseSyncStatePB syncState,
  ) = syncStateChanged;
}

@freezed
class DatabaseSyncBlocState with _$DatabaseSyncBlocState {
  const factory DatabaseSyncBlocState({
    required DatabaseSyncState syncState,
    @Default(true) bool isNetworkConnected,
    @Default(false) bool shouldShowIndicator,
  }) = _DatabaseSyncState;

  factory DatabaseSyncBlocState.initial() => const DatabaseSyncBlocState(
        syncState: DatabaseSyncState.Syncing,
      );
}
