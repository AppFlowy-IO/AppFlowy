import 'dart:async';
import 'dart:convert';

import 'package:appflowy/plugins/document/application/doc_awareness_metadata.dart';
import 'package:appflowy/plugins/document/application/doc_listener.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/auth/device_id.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'doc_awareness_bloc.freezed.dart';

class DocumentCollaboratorsBloc
    extends Bloc<DocumentCollaboratorsEvent, DocumentCollaboratorsState> {
  DocumentCollaboratorsBloc({
    required this.view,
  })  : _listener = DocumentListener(id: view.id),
        super(DocumentCollaboratorsState.initial()) {
    on<DocumentCollaboratorsEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            final userProfile = await getIt<AuthService>().getUser().then(
                  (result) => result.fold(
                    (l) => l,
                    (r) => null,
                  ),
                );
            final deviceId = await getDeviceId();
            _listener.start(
              onDocAwarenessUpdate: (states) {
                if (!isClosed && userProfile != null) {
                  final metadata = _buildMetadata(
                    userProfile,
                    deviceId,
                    states,
                  );
                  emit(state.copyWith(metadata: metadata));
                }
              },
            );
          },
        );
      },
    );
  }

  final ViewPB view;
  final DocumentListener _listener;

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }

  List<DocumentAwarenessMetadata> _buildMetadata(
    UserProfilePB userProfile,
    String deviceId,
    DocumentAwarenessStatesPB states,
  ) {
    final result = <DocumentAwarenessMetadata>[];
    for (final state in states.value.values) {
      // filter current user
      if (userProfile.id == state.user.uid && deviceId == state.user.deviceId) {
        continue;
      }
      try {
        final metadata = DocumentAwarenessMetadata.fromJson(
          jsonDecode(state.metadata),
        );
        result.add(metadata);
      } catch (e) {
        Log.error('Failed to parse metadata: $e');
      }
    }
    return result;
  }
}

@freezed
class DocumentCollaboratorsEvent with _$DocumentCollaboratorsEvent {
  const factory DocumentCollaboratorsEvent.initial() = Initial;
}

@freezed
class DocumentCollaboratorsState with _$DocumentCollaboratorsState {
  const factory DocumentCollaboratorsState({
    @Default([]) List<DocumentAwarenessMetadata> metadata,
  }) = _DocumentCollaboratorsState;

  factory DocumentCollaboratorsState.initial() =>
      const DocumentCollaboratorsState();
}
