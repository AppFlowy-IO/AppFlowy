import React, { lazy, Suspense, useCallback, useEffect, useMemo, useState } from 'react';
import { useAuth } from '@/components/auth/auth.hooks';
import { currentUserActions, LoginState } from '@/stores/currentUser/slice';
import { useAppDispatch } from '@/stores/store';
import { getPlatform } from '@/utils/platform';
import SplashScreen from '@/components/auth/SplashScreen';
import CircularProgress from '@mui/material/CircularProgress';
import Portal from '@mui/material/Portal';
import { ReactComponent as Logo } from '@/assets/logo.svg';

const TauriAuth = lazy(() => import('@/components/tauri/TauriAuth'));

function ProtectedRoutes () {
  const { currentUser, checkUser } = useAuth();

  const isLoading = currentUser?.loginState === LoginState.LOADING;
  const [checked, setChecked] = useState(false);

  const checkUserStatus = useCallback(async () => {
    try {
      await checkUser();
    } finally {
      setChecked(true);
    }
  }, [checkUser]);

  useEffect(() => {
    void checkUserStatus();
  }, [checkUserStatus]);

  const platform = useMemo(() => getPlatform(), []);

  return (
    <div className={'relative h-screen w-screen'}>
      {checked ? (
        <SplashScreen isAuthenticated={currentUser.isAuthenticated}/>
      ) : (
        <div className={'flex h-screen w-screen items-center justify-center'}>
          <Logo className={'h-20 w-20'}/>
        </div>
      )}

      {isLoading && <StartLoading/>}
      <Suspense>{platform.isTauri && <TauriAuth/>}</Suspense>
    </div>
  );
}

export default ProtectedRoutes;

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
        <CircularProgress/>
      </div>
    </Portal>
  );
};
