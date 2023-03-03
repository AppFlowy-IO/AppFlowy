import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from './auth.hooks';
import { Screen } from '../layout/Screen';
import { useEffect } from 'react';

export const ProtectedRoutes = () => {
  const { currentUser, checkUser } = useAuth();

  useEffect(() => {
    void checkUser().then(console.error);
  }, []);

  return <SplashScreen isAuthenticated={currentUser.isAuthenticated} />;
};

const SplashScreen = ({ isAuthenticated }: { isAuthenticated: boolean }) => {
  const location = useLocation();
  if (isAuthenticated) {
    return (
      <Screen>
        <Outlet />
      </Screen>
    );
  } else {
    return <Navigate to='/auth/getStarted' replace state={{ from: location }} />;
  }
};
