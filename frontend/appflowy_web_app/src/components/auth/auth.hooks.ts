import { useAppDispatch, useAppSelector } from '@/stores/store';
import { useCallback, useContext } from 'react';
import { nanoid } from 'nanoid';
import { open } from '@tauri-apps/api/shell';
import { ProviderType, UserProfile } from '@/application/user.type';
import { currentUserActions } from '@/stores/currentUser/slice';
import { AFConfigContext } from '@/AppConfig';
import { notify } from '@/components/_shared/notify';

export const useAuth = () => {
  const dispatch = useAppDispatch();
  const AFConfig = useContext(AFConfigContext);
  const currentUser = useAppSelector((state) => state.currentUser);
  const isReady = !!AFConfig?.service;

  const handleSuccess = useCallback(() => {
    notify.clear();
    dispatch(currentUserActions.loginSuccess());
  }, [dispatch]);
  const setUser = useCallback(
    async (userProfile: UserProfile) => {
      handleSuccess();
      dispatch(currentUserActions.updateUser(userProfile));
    },
    [dispatch, handleSuccess],
  );

  const handleStart = useCallback(() => {
    notify.clear();
    notify.loading('Loading...');
    dispatch(currentUserActions.loginStart());
  }, [dispatch]);

  const handleError = useCallback(
    ({ message }: { message: string }) => {
      notify.clear();
      notify.error(message);
      dispatch(currentUserActions.loginError());
    },
    [dispatch],
  );

  // Check if the user is authenticated
  const checkUser = useCallback(async () => {

    try {
      const userProfile = await AFConfig?.service?.userService.getUserProfile();

      if (!userProfile) {
        throw new Error('Failed to check user');
      }

      await setUser(userProfile);

      return userProfile;
    } catch (e) {

      return Promise.reject('Failed to check user');
    }
  }, [AFConfig?.service?.userService, setUser]);

  const register = useCallback(
    async (email: string, password: string, name: string): Promise<UserProfile | null> => {
      handleStart();
      try {
        const userProfile = await AFConfig?.service?.authService.signupWithEmailPassword({
          email,
          password,
          name,
        });

        if (!userProfile) {
          throw new Error('Failed to register');
        }

        await setUser(userProfile);

        return userProfile;
      } catch (e) {
        handleError({
          message: 'Failed to register',
        });
        return null;
      }
    },
    [handleStart, AFConfig?.service?.authService, setUser, handleError],
  );

  const logout = useCallback(async () => {
    try {
      await AFConfig?.service?.authService.signOut();
      dispatch(currentUserActions.logout());
    } catch (e) {
      handleError({
        message: 'Failed to logout',
      });
    }
  }, [AFConfig?.service?.authService, dispatch, handleError]);

  const signInAsAnonymous = useCallback(async () => {
    const fakeEmail = nanoid(8) + '@appflowy.io';
    const fakePassword = 'AppFlowy123@';
    const fakeName = 'Me';

    await register(fakeEmail, fakePassword, fakeName);
  }, [register]);

  const signInWithProvider = useCallback(
    async (provider: ProviderType) => {
      handleStart();
      try {
        const url = await AFConfig?.service?.authService.getOAuthURL(provider);

        if (!url) {
          throw new Error('Failed to sign in');
        }

        await open(url);
      } catch {
        handleError({
          message: 'Failed to sign in',
        });
      }
    },
    [AFConfig?.service?.authService, handleError, handleStart],
  );

  const signInWithOAuth = useCallback(
    async (uri: string) => {
      handleStart();
      try {
        await AFConfig?.service?.authService.signInWithOAuth({ uri });
        const userProfile = await AFConfig?.service?.userService.getUserProfile();

        if (!userProfile) {
          throw new Error('Failed to sign in');
        }

        await setUser(userProfile);

        return userProfile;
      } catch (e) {
        handleError({
          message: 'Failed to sign in',
        });
      }
    },
    [AFConfig?.service?.authService, AFConfig?.service?.userService, handleError, handleStart, setUser],
  );

  const signInWithEmailPassword = useCallback(
    async (email: string, password: string) => {
      handleStart();
      try {
        await AFConfig?.service?.authService.signinWithEmailPassword(email, password);

        const userProfile = await AFConfig?.service?.userService.getUserProfile();

        console.log('userProfile', userProfile);
        if (!userProfile) {
          throw new Error('Failed to sign in');
        }

        await setUser(userProfile);

        return userProfile;
      } catch (e) {
        handleError({
          message: 'Failed to sign in',
        });
      }
    },
    [AFConfig?.service?.authService, AFConfig?.service?.userService, handleError, handleStart, setUser],
  );

  return {
    isReady,
    currentUser,
    checkUser,
    register,
    logout,
    signInWithProvider,
    signInAsAnonymous,
    signInWithOAuth,
    signInWithEmailPassword,
  };
};
