import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

/// Abstract repository for workspace operations.
///
/// This abstracts the data source for workspace operations,
/// allowing for different implementations (e.g., REST API, gRPC, local storage).
abstract class WorkspaceRepository {
  /// Gets the current workspace for the user.
  Future<FlowyResult<WorkspacePB, FlowyError>> getCurrentWorkspace();

  /// Gets the list of workspaces for the current user.
  Future<FlowyResult<List<UserWorkspacePB>, FlowyError>> getWorkspaces();

  /// Creates a new workspace.
  Future<FlowyResult<UserWorkspacePB, FlowyError>> createWorkspace({
    required String name,
    required WorkspaceTypePB workspaceType,
  });

  /// Deletes a workspace by ID.
  Future<FlowyResult<void, FlowyError>> deleteWorkspace({
    required String workspaceId,
  });

  /// Opens a workspace.
  Future<FlowyResult<void, FlowyError>> openWorkspace({
    required String workspaceId,
    required WorkspaceTypePB workspaceType,
  });

  /// Renames a workspace.
  Future<FlowyResult<void, FlowyError>> renameWorkspace({
    required String workspaceId,
    required String name,
  });

  /// Updates workspace icon.
  Future<FlowyResult<void, FlowyError>> updateWorkspaceIcon({
    required String workspaceId,
    required String icon,
  });

  /// Leaves a workspace.
  Future<FlowyResult<void, FlowyError>> leaveWorkspace({
    required String workspaceId,
  });

  /// Gets workspace subscription information.
  Future<FlowyResult<WorkspaceSubscriptionInfoPB, FlowyError>>
      getWorkspaceSubscriptionInfo({
    required String workspaceId,
  });

  /// Is billing enabled.
  Future<bool> isBillingEnabled();
}
