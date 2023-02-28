import { currentUserActions } from '../../stores/reducers/current-user/slice';
import { useAppDispatch, useAppSelector } from '../../stores/store';
import { UserProfilePB } from '../../../services/backend/events/flowy-user';
import { AuthBackendService } from '../../stores/effects/user/user_bd_svc';
import { FolderEventReadCurrentWorkspace } from '../../../services/backend/events/flowy-folder';
import { WorkspaceSettingPB } from '../../../services/backend/models/flowy-folder/workspace';

export const useAuth = () => {
  const dispatch = useAppDispatch();
  const currentUser = useAppSelector((state) => state.currentUser);
  const authBackendService = new AuthBackendService();

  async function register(email: string, password: string, name: string): Promise<UserProfilePB> {
    const authResult = await authBackendService.signUp({ email, password, name });

    if (authResult.ok) {
      const { id, token } = authResult.val;
      // Get the workspace setting after user registered. The workspace setting
      // contains the latest visiting view and the current workspace data.
      const openWorkspaceResult = await _openWorkspace();
      if (openWorkspaceResult.ok) {
        const workspaceSetting: WorkspaceSettingPB = openWorkspaceResult.val;
        dispatch(
          currentUserActions.updateUser({
            id: id,
            token: token,
            email,
            displayName: name,
            isAuthenticated: true,
            workspaceSetting: workspaceSetting,
          })
        );
      }
      return authResult.val;
    } else {
      console.error(authResult.val.msg);
      throw new Error(authResult.val.msg);
    }
  }

  async function login(email: string, password: string): Promise<UserProfilePB> {
    const result = await authBackendService.signIn({ email, password });
    if (result.ok) {
      const { id, token, name } = result.val;
      dispatch(
        currentUserActions.updateUser({
          id: id,
          token: token,
          email,
          displayName: name,
          isAuthenticated: true,
        })
      );
      return result.val;
    } else {
      console.error(result.val.msg);
      throw new Error(result.val.msg);
    }
  }

  async function logout() {
    await authBackendService.signOut();
    dispatch(currentUserActions.logout());
  }

  async function _openWorkspace() {
    return FolderEventReadCurrentWorkspace();
  }

  return { currentUser, register, login, logout };
};
