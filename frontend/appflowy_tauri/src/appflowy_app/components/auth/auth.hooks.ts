import { currentUserActions } from '$app_reducers/current-user/slice';
import { AuthenticatorPB, UserNotification, UserProfilePB } from '@/services/backend/events/flowy-user';
import { UserService } from '$app/application/user/user.service';
import { AuthService } from '$app/application/user/auth.service';
import { useAppSelector, useAppDispatch } from '$app/stores/store';
import { getCurrentWorkspaceSetting } from '$app/application/folder/workspace.service';
import { useCallback } from 'react';
import { subscribeNotifications } from '$app/application/notification';

export const useAuth = () => {
  const dispatch = useAppDispatch();
  const currentUser = useAppSelector((state) => state.currentUser);

  const subscribeToUser = useCallback(() => {
    const unsubscribePromise = subscribeNotifications({
      [UserNotification.DidUpdateUserProfile]: async (changeset) => {
        dispatch(
          currentUserActions.updateUser({
            email: changeset.email,
            displayName: changeset.name,
            iconUrl: changeset.icon_url,
          })
        );
      },
    });

    return () => {
      void unsubscribePromise.then((fn) => fn());
    };
  }, [dispatch]);

  const checkUser = useCallback(async () => {
    const userProfile = await UserService.getUserProfile();

    if (!userProfile) return;
    const workspaceSetting = await getCurrentWorkspaceSetting();

    const isLocal = userProfile.authenticator === AuthenticatorPB.Local;

    dispatch(
      currentUserActions.checkUser({
        id: userProfile.id,
        token: userProfile.token,
        email: userProfile.email,
        displayName: userProfile.name,
        iconUrl: userProfile.icon_url,
        isAuthenticated: true,
        workspaceSetting: workspaceSetting,
        isLocal,
      })
    );

    return userProfile;
  }, [dispatch]);

  const register = useCallback(
    async (email: string, password: string, name: string): Promise<UserProfilePB> => {
      const userProfile = await AuthService.signUp({ email, password, name });

      // Get the workspace setting after user registered. The workspace setting
      // contains the latest visiting page and the current workspace data.
      const workspaceSetting = await getCurrentWorkspaceSetting();

      if (workspaceSetting) {
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

      return userProfile;
    },
    [dispatch]
  );

  const login = useCallback(
    async (email: string, password: string): Promise<UserProfilePB> => {
      const user = await AuthService.signIn({ email, password });
      const { id, token, name } = user;

      dispatch(
        currentUserActions.updateUser({
          id: id,
          token: token,
          email,
          displayName: name,
          isAuthenticated: true,
        })
      );
      return user;
    },
    [dispatch]
  );

  const logout = useCallback(async () => {
    await AuthService.signOut();
    dispatch(currentUserActions.logout());
  }, [dispatch]);

  return { currentUser, checkUser, register, login, logout, subscribeToUser };
};
