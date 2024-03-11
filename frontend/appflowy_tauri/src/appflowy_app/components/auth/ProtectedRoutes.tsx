import { Outlet } from 'react-router-dom';
import { useAuth } from './auth.hooks';
import Layout from '$app/components/layout/Layout';
import { useCallback, useEffect, useState } from 'react';
import { GetStarted } from '$app/components/auth/get_started/GetStarted';
import { AppflowyLogo } from '../_shared/svg/AppflowyLogo';

export const ProtectedRoutes = () => {
  const { currentUser, checkUser, subscribeToUser } = useAuth();
  const [isLoading, setIsLoading] = useState(true);

  const checkUserStatus = useCallback(async () => {
    await checkUser();
    setIsLoading(false);
  }, [checkUser]);

  useEffect(() => {
    void checkUserStatus();
  }, [checkUserStatus]);

  useEffect(() => {
    if (currentUser.isAuthenticated) {
      return subscribeToUser();
    }
  }, [currentUser.isAuthenticated, subscribeToUser]);

  if (isLoading) {
    // It's better to make a fading effect to disappear the loading page
    return <StartLoading />;
  } else {
    return <SplashScreen isAuthenticated={currentUser.isAuthenticated} />;
  }
};

const StartLoading = () => {
  return (
    <div className='flex h-screen w-full flex-col items-center justify-center'>
      <div className='h-40 w-40 justify-center'>
        <AppflowyLogo />
      </div>
    </div>
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
    return <GetStarted />;
  }
};
