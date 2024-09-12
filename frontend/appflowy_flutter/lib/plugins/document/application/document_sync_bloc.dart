import 'dart:async';

import 'package:appflowy/plugins/document/application/doc_sync_state_listener.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_sync_bloc.freezed.dart';

class DocumentSyncBloc extends Bloc<DocumentSyncEvent, DocumentSyncBlocState> {
  DocumentSyncBloc({
    required this.view,
  })  : _syncStateListener = DocumentSyncStateListener(id: view.id),
        super(DocumentSyncBlocState.initial()) {
    on<DocumentSyncEvent>(
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
                    userProfile?.authenticator == AuthenticatorPB.AppFlowyCloud,
              ),
            );
            _syncStateListener.start(
              didReceiveSyncState: (syncState) {
                add(DocumentSyncEvent.syncStateChanged(syncState));
              },
            );

            final isNetworkConnected = await _connectivity
                .checkConnectivity()
                .then((value) => !value.contains(ConnectivityResult.none));
            emit(state.copyWith(isNetworkConnected: isNetworkConnected));

            connectivityStream =
                _connectivity.onConnectivityChanged.listen((result) {
              add(DocumentSyncEvent.networkStateChanged(result));
            });
          },
          syncStateChanged: (syncState) {
            emit(state.copyWith(syncState: syncState.value));
          },
          networkStateChanged: (result) {
            emit(
              state.copyWith(
                isNetworkConnected: !result.contains(ConnectivityResult.none),
              ),
            );
          },
        );
      },
    );
  }

  final ViewPB view;
  final DocumentSyncStateListener _syncStateListener;
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
class DocumentSyncEvent with _$DocumentSyncEvent {
  const factory DocumentSyncEvent.initial() = Initial;
  const factory DocumentSyncEvent.syncStateChanged(
    DocumentSyncStatePB syncState,
  ) = syncStateChanged;
  const factory DocumentSyncEvent.networkStateChanged(
    List<ConnectivityResult> result,
  ) = NetworkStateChanged;
}

@freezed
class DocumentSyncBlocState with _$DocumentSyncBlocState {
  const factory DocumentSyncBlocState({
    required DocumentSyncState syncState,
    @Default(true) bool isNetworkConnected,
    @Default(false) bool shouldShowIndicator,
  }) = _DocumentSyncState;

  factory DocumentSyncBlocState.initial() => const DocumentSyncBlocState(
        syncState: DocumentSyncState.Syncing,
      );
}
