import { Outlet } from 'react-router-dom';
import { useAuth } from './auth.hooks';
import Layout from '$app/components/layout/Layout';
import { useCallback, useEffect, useState } from 'react';
import { Welcome } from '$app/components/auth/Welcome';
import { isTauri } from '$app/utils/env';
import { notify } from '$app/components/_shared/notify';
import { currentUserActions, LoginState } from '$app_reducers/current-user/slice';
import { CircularProgress, Portal } from '@mui/material';
import { ReactComponent as Logo } from '$app/assets/logo.svg';
import { useAppDispatch } from '$app/stores/store';

export const ProtectedRoutes = () => {
  const { currentUser, checkUser, subscribeToUser, signInWithOAuth } = useAuth();
  const dispatch = useAppDispatch();

  const isLoading = currentUser?.loginState === LoginState.Loading;

  const [checked, setChecked] = useState(false);

  const checkUserStatus = useCallback(async () => {
    await checkUser();
    setChecked(true);
  }, [checkUser]);

  useEffect(() => {
    void checkUserStatus();
  }, [checkUserStatus]);

  useEffect(() => {
    if (currentUser.isAuthenticated) {
      return subscribeToUser();
    }
  }, [currentUser.isAuthenticated, subscribeToUser]);

  const onDeepLink = useCallback(async () => {
    if (!isTauri()) return;
    const { event } = await import('@tauri-apps/api');

    // On macOS You still have to install a .app bundle you got from tauri build --debug for this to work!
    return await event.listen('open_deep_link', async (e) => {
      const payload = e.payload as string;

      const [, hash] = payload.split('//#');
      const obj = parseHash(hash);

      if (!obj.access_token) {
        notify.error('Failed to sign in, the access token is missing');
        dispatch(currentUserActions.setLoginState(LoginState.Error));
        return;
      }

      try {
        await signInWithOAuth(payload);
      } catch (e) {
        notify.error('Failed to sign in, please try again');
      }
    });
  }, [dispatch, signInWithOAuth]);

  useEffect(() => {
    void onDeepLink();
  }, [onDeepLink]);

  return (
    <div className={'relative h-screen w-screen'}>
      {checked ? (
        <SplashScreen isAuthenticated={currentUser.isAuthenticated} />
      ) : (
        <div className={'flex h-screen w-screen items-center justify-center'}>
          <Logo className={'h-20 w-20'} />
        </div>
      )}

      {isLoading && <StartLoading />}
    </div>
  );
};

const StartLoading = () => {
  const dispatch = useAppDispatch();

  useEffect(() => {
    const preventDefault = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        dispatch(currentUserActions.resetLoginState());
      }
    };

    document.addEventListener('keydown', preventDefault, true);

    return () => {
      document.removeEventListener('keydown', preventDefault, true);
    };
  }, [dispatch]);
  return (
    <Portal>
      <div className={'fixed inset-0 z-[1400] flex h-full w-full items-center justify-center bg-bg-mask bg-opacity-50'}>
        <CircularProgress />
      </div>
    </Portal>
  );
};

const SplashScreen = ({ isAuthenticated }: { isAuthenticated: boolean }) => {
  if (isAuthenticated) {
    return (
      <Layout>
        <Outlet />
      </Layout>
    );
  } else {
    return <Welcome />;
  }
};

function parseHash(hash: string) {
  const hashParams = new URLSearchParams(hash);
  const hashObject: Record<string, string> = {};

  for (const [key, value] of hashParams) {
    hashObject[key] = value;
  }

  return hashObject;
}
