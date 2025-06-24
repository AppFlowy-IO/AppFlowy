import 'package:appflowy/features/workspace/data/repositories/workspace_repository.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart'
    as billing_service;
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:fixnum/fixnum.dart';

/// Implementation of WorkspaceRepository using UserBackendService.
class RustWorkspaceRepositoryImpl implements WorkspaceRepository {
  RustWorkspaceRepositoryImpl({
    required Int64 userId,
  }) : _userService = UserBackendService(userId: userId);

  final UserBackendService _userService;

  @override
  Future<FlowyResult<WorkspacePB, FlowyError>> getCurrentWorkspace() async {
    return UserBackendService.getCurrentWorkspace();
  }

  @override
  Future<FlowyResult<List<UserWorkspacePB>, FlowyError>> getWorkspaces() async {
    return _userService.getWorkspaces();
  }

  @override
  Future<FlowyResult<UserWorkspacePB, FlowyError>> createWorkspace({
    required String name,
    required WorkspaceTypePB workspaceType,
  }) async {
    return _userService.createUserWorkspace(name, workspaceType);
  }

  @override
  Future<FlowyResult<void, FlowyError>> deleteWorkspace({
    required String workspaceId,
  }) async {
    return _userService.deleteWorkspaceById(workspaceId);
  }

  @override
  Future<FlowyResult<void, FlowyError>> openWorkspace({
    required String workspaceId,
    required WorkspaceTypePB workspaceType,
  }) async {
    return _userService.openWorkspace(workspaceId, workspaceType);
  }

  @override
  Future<FlowyResult<void, FlowyError>> renameWorkspace({
    required String workspaceId,
    required String name,
  }) async {
    return _userService.renameWorkspace(workspaceId, name);
  }

  @override
  Future<FlowyResult<void, FlowyError>> updateWorkspaceIcon({
    required String workspaceId,
    required String icon,
  }) async {
    return _userService.updateWorkspaceIcon(workspaceId, icon);
  }

  @override
  Future<FlowyResult<void, FlowyError>> leaveWorkspace({
    required String workspaceId,
  }) async {
    return _userService.leaveWorkspace(workspaceId);
  }

  @override
  Future<FlowyResult<WorkspaceSubscriptionInfoPB, FlowyError>>
      getWorkspaceSubscriptionInfo({
    required String workspaceId,
  }) async {
    return UserBackendService.getWorkspaceSubscriptionInfo(workspaceId);
  }

  @override
  Future<bool> isBillingEnabled() async {
    return billing_service.isBillingEnabled();
  }
}
