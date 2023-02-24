import { currentUserActions } from '../../stores/reducers/current-user/slice';
import { useAppDispatch, useAppSelector } from '../../stores/store';
import { UserProfilePB } from '../../../services/backend/events/flowy-user';
import { AuthBackendService, UserBackendService } from '../../stores/effects/user/backend_service';

export const useAuth = () => {
  const dispatch = useAppDispatch();
  const currentUser = useAppSelector((state) => state.currentUser);
  const authBackendService = new AuthBackendService();
  let userBackendService: UserBackendService;

  async function register(email: string, password: string, name: string): Promise<UserProfilePB> {
    const result = await authBackendService.signUp({ email, password, name });
    if (result.ok) {
      const { id, token } = result.val;
      userBackendService = new UserBackendService(id);
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

  async function login(email: string, password: string): Promise<UserProfilePB> {
    const result = await authBackendService.signIn({ email, password });
    if (result.ok) {
      const { id, token, name } = result.val;
      userBackendService = new UserBackendService(id);
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

  return { currentUser, register, login, logout };
};
