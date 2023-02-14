import { currentUserActions } from '../../stores/reducers/current-user/slice';
import { useAppDispatch, useAppSelector } from '../../stores/store';
import { SignInPayloadPB, UserEventSignIn, UserProfilePB } from '../../../services/backend/events/flowy-user';

export const useAuth = () => {
  const dispatch = useAppDispatch();

  const currentUser = useAppSelector((state) => state.currentUser);

  async function login(email: string, password: string, name: string): Promise<UserProfilePB> {
    const signInResult = await UserEventSignIn(
      SignInPayloadPB.fromObject({
        email,
        password,
        name,
      })
    );
    if (signInResult.ok) {
      return signInResult.val;
    } else {
      throw new Error('sign in error');
    }
  }

  function logout() {
    dispatch(currentUserActions.logout());
  }

  return { currentUser, login, logout };
};
