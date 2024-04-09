import 'dart:async';
import 'dart:convert';

import 'package:appflowy/plugins/document/application/document_awareness_metadata.dart';
import 'package:appflowy/plugins/document/application/document_listener.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/device_info_task.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_collaborators_bloc.freezed.dart';

bool _filterCurrentUser = false;

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
            final result = await getIt<AuthService>().getUser();
            final userProfile = result.fold((s) => s, (f) => null);
            emit(
              state.copyWith(
                shouldShowIndicator:
                    userProfile?.authenticator == AuthenticatorPB.AppFlowyCloud,
              ),
            );
            final deviceId = ApplicationInfo.deviceId;
            if (userProfile != null) {
              _listener.start(
                onDocAwarenessUpdate: (states) {
                  add(
                    DocumentCollaboratorsEvent.update(
                      userProfile,
                      deviceId,
                      states,
                    ),
                  );
                },
              );
            }
          },
          update: (userProfile, deviceId, states) {
            final collaborators = _buildCollaborators(
              userProfile,
              deviceId,
              states,
            );
            emit(state.copyWith(collaborators: collaborators));
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

  List<DocumentAwarenessMetadata> _buildCollaborators(
    UserProfilePB userProfile,
    String deviceId,
    DocumentAwarenessStatesPB states,
  ) {
    final result = <DocumentAwarenessMetadata>[];
    final ids = <dynamic>{};
    final sorted = states.value.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp))
      ..retainWhere((e) => ids.add(e.user.uid.toString() + e.user.deviceId));
    for (final state in sorted) {
      if (state.version != 1) {
        continue;
      }
      // filter current user
      if (_filterCurrentUser &&
          userProfile.id == state.user.uid &&
          deviceId == state.user.deviceId) {
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
  const factory DocumentCollaboratorsEvent.update(
    UserProfilePB userProfile,
    String deviceId,
    DocumentAwarenessStatesPB states,
  ) = Update;
}

@freezed
class DocumentCollaboratorsState with _$DocumentCollaboratorsState {
  const factory DocumentCollaboratorsState({
    @Default([]) List<DocumentAwarenessMetadata> collaborators,
    @Default(false) bool shouldShowIndicator,
  }) = _DocumentCollaboratorsState;

  factory DocumentCollaboratorsState.initial() =>
      const DocumentCollaboratorsState();
}
