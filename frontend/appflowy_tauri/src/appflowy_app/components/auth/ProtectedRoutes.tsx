import { Outlet } from 'react-router-dom';
import { useAuth } from './auth.hooks';
import { Screen } from '../layout/Screen';
import { useEffect, useState } from 'react';
import { GetStarted } from './GetStarted/GetStarted';
import { AppflowyLogo } from '../_shared/svg/AppflowyLogo';

export const ProtectedRoutes = () => {
  const { currentUser, checkUser } = useAuth();
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    void checkUser().then(async (result) => {
      if (result.err) {
        throw new Error(result.val.msg);
      }
      await new Promise(() =>
        setTimeout(() => {
          setIsLoading(false);
        }, 1000)
      );
    });
  }, []);

  if (isLoading) {
    return (
      <div className='flex h-screen w-full flex-col items-center justify-center'>
        <div className='h-40 w-40 justify-center'>
          <AppflowyLogo />
        </div>
      </div>
    );
  } else {
    return <SplashScreen isAuthenticated={currentUser.isAuthenticated} />;
  }
};

const SplashScreen = ({ isAuthenticated }: { isAuthenticated: boolean }) => {
  if (isAuthenticated) {
    return (
      <Screen>
        <Outlet />
      </Screen>
    );
  } else {
    return <GetStarted></GetStarted>;
  }
};
