import { currentUserActions } from '../../stores/reducers/current-user/slice';
import { useAppDispatch, useAppSelector } from '../../stores/store';
import { UserProfilePB } from '../../../services/backend/events/flowy-user';
import { AuthBackendService, UserBackendService } from '../../stores/effects/user/user_bd_svc';
import { FolderEventGetCurrentWorkspace } from '../../../services/backend/events/flowy-folder2';
import { WorkspaceSettingPB } from '../../../services/backend/models/flowy-folder2/workspace';
import { Log } from '../../utils/log';

export const useAuth = () => {
  const dispatch = useAppDispatch();
  const currentUser = useAppSelector((state) => state.currentUser);
  const authBackendService = new AuthBackendService();

  async function checkUser() {
    const result = await UserBackendService.checkUser();
    if (result.ok) {
      const userProfile = result.val;
      const workspaceSetting = await _openWorkspace().then((r) => {
        if (r.ok) {
          return r.val;
        } else {
          return undefined;
        }
      });
      dispatch(
        currentUserActions.checkUser({
          id: userProfile.id,
          token: userProfile.token,
          email: userProfile.email,
          displayName: userProfile.name,
          isAuthenticated: true,
          workspaceSetting: workspaceSetting,
        })
      );
    }
    return result;
  }

  async function register(email: string, password: string, name: string): Promise<UserProfilePB> {
    const authResult = await authBackendService.signUp({ email, password, name });

    if (authResult.ok) {
      const userProfile = authResult.val;
      // Get the workspace setting after user registered. The workspace setting
      // contains the latest visiting view and the current workspace data.
      const openWorkspaceResult = await _openWorkspace();
      if (openWorkspaceResult.ok) {
        const workspaceSetting: WorkspaceSettingPB = openWorkspaceResult.val;
        dispatch(
          currentUserActions.updateUser({
            id: userProfile.id,
            token: userProfile.token,
            email: userProfile.email,
            displayName: userProfile.name,
            isAuthenticated: true,
            workspaceSetting: workspaceSetting,
          })
        );
      }
      return authResult.val;
    } else {
      Log.error(authResult.val.msg);
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
      Log.error(result.val.msg);
      throw new Error(result.val.msg);
    }
  }

  async function logout() {
    await authBackendService.signOut();
    dispatch(currentUserActions.logout());
  }

  async function _openWorkspace() {
    return FolderEventGetCurrentWorkspace();
  }

  return { currentUser, checkUser, register, login, logout };
};
