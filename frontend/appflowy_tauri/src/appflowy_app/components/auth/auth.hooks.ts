import { currentUserActions, LoginState, parseWorkspaceSettingPBToSetting } from '$app_reducers/current-user/slice';
import { AuthenticatorPB, ProviderTypePB, UserNotification, UserProfilePB } from '@/services/backend/events/flowy-user';
import { UserService } from '$app/application/user/user.service';
import { AuthService } from '$app/application/user/auth.service';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { getCurrentWorkspaceSetting } from '$app/application/folder/workspace.service';
import { useCallback } from 'react';
import { subscribeNotifications } from '$app/application/notification';
import { nanoid } from 'nanoid';
import { open } from '@tauri-apps/api/shell';

export const useAuth = () => {
  const dispatch = useAppDispatch();
  const currentUser = useAppSelector((state) => state.currentUser);

  // Subscribe to user update events
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

  const setUser = useCallback(
    async (userProfile?: Partial<UserProfilePB>) => {
      if (!userProfile) return;

      const workspaceSetting = await getCurrentWorkspaceSetting();

      const isLocal = userProfile.authenticator === AuthenticatorPB.Local;

      dispatch(
        currentUserActions.updateUser({
          id: userProfile.id,
          token: userProfile.token,
          email: userProfile.email,
          displayName: userProfile.name,
          iconUrl: userProfile.icon_url,
          isAuthenticated: true,
          workspaceSetting: workspaceSetting ? parseWorkspaceSettingPBToSetting(workspaceSetting) : undefined,
          isLocal,
        })
      );
    },
    [dispatch]
  );

  // Check if the user is authenticated
  const checkUser = useCallback(async () => {
    const userProfile = await UserService.getUserProfile();

    await setUser(userProfile);

    return userProfile;
  }, [setUser]);

  const register = useCallback(
    async (email: string, password: string, name: string): Promise<UserProfilePB> => {
      const deviceId = currentUser?.deviceId ?? nanoid(8);
      const userProfile = await AuthService.signUp({ deviceId, email, password, name });

      await setUser(userProfile);

      return userProfile;
    },
    [setUser, currentUser?.deviceId]
  );

  const logout = useCallback(async () => {
    await AuthService.signOut();
    dispatch(currentUserActions.logout());
  }, [dispatch]);

  const signInAsAnonymous = useCallback(async () => {
    const fakeEmail = nanoid(8) + '@appflowy.io';
    const fakePassword = 'AppFlowy123@';
    const fakeName = 'Me';

    await register(fakeEmail, fakePassword, fakeName);
  }, [register]);

  const signIn = useCallback(
    async (provider: ProviderTypePB) => {
      dispatch(currentUserActions.setLoginState(LoginState.Loading));
      try {
        const url = await AuthService.getOAuthURL(provider);

        await open(url);
      } catch {
        dispatch(currentUserActions.setLoginState(LoginState.Error));
      }
    },
    [dispatch]
  );

  const signInWithOAuth = useCallback(
    async (uri: string) => {
      dispatch(currentUserActions.setLoginState(LoginState.Loading));
      try {
        const deviceId = currentUser?.deviceId ?? nanoid(8);

        await AuthService.signInWithOAuth({ uri, deviceId });
        const userProfile = await UserService.getUserProfile();

        await setUser(userProfile);

        return userProfile;
      } catch (e) {
        dispatch(currentUserActions.setLoginState(LoginState.Error));
        return Promise.reject(e);
      }
    },
    [dispatch, currentUser?.deviceId, setUser]
  );

  // Only for development purposes
  const signInWithEmailPassword = useCallback(
    async (email: string, password: string, domain?: string) => {
      dispatch(currentUserActions.setLoginState(LoginState.Loading));

      try {
        const response = await fetch(
          `https://${domain ? domain : 'test.appflowy.cloud'}/gotrue/token?grant_type=password`,
          {
            method: 'POST',
            mode: 'cors',
            cache: 'no-cache',
            credentials: 'same-origin',
            headers: {
              'Content-Type': 'application/json',
            },
            redirect: 'follow',
            referrerPolicy: 'no-referrer',
            body: JSON.stringify({
              email,
              password,
            }),
          }
        );

        const data = await response.json();

        let uri = `appflowy-flutter://#`;
        const params: string[] = [];

        Object.keys(data).forEach((key) => {
          if (typeof data[key] === 'object') {
            return;
          }

          params.push(`${key}=${data[key]}`);
        });
        uri += params.join('&');

        return signInWithOAuth(uri);
      } catch (e) {
        dispatch(currentUserActions.setLoginState(LoginState.Error));
        return Promise.reject(e);
      }
    },
    [dispatch, signInWithOAuth]
  );

  return {
    currentUser,
    checkUser,
    register,
    logout,
    subscribeToUser,
    signInAsAnonymous,
    signIn,
    signInWithOAuth,
    signInWithEmailPassword,
  };
};
