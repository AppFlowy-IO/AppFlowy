import { Outlet } from 'react-router-dom';
import { useAuth } from './auth.hooks';
import Layout from '$app/components/layout/Layout';
import { useEffect, useState } from 'react';
import { GetStarted } from './GetStarted/GetStarted';
import { AppflowyLogo } from '../_shared/svg/AppflowyLogo';

export const ProtectedRoutes = () => {
  const { currentUser, checkUser } = useAuth();
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    void checkUser().then(async (result) => {
      await new Promise(() =>
        setTimeout(() => {
          setIsLoading(false);
        }, 1200)
      );

      if (result.err) {
        throw new Error(result.val.msg);
      }
    });
  }, []);

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
    return <GetStarted></GetStarted>;
  }
};
