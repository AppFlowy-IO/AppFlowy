import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from './auth.hooks';
import { Screen } from '../layout/Screen';

export const ProtectedRoutes = () => {
  const location = useLocation();
  const { currentUser } = useAuth();

  return currentUser.isAuthenticated ? (
    <Screen>
      <Outlet />
    </Screen>
  ) : (
    <Navigate to='/auth/getStarted' replace state={{ from: location }} />
  );
};
