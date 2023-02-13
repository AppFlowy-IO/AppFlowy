import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from './auth.hooks';
import { Screen } from '../../components/layout/Screen';

export const ProtectedRoutes = () => {
  const location = useLocation();
  const { currentUser } = useAuth();

  return currentUser.isAuthenticated ? (
    <Screen>
      <Outlet />
    </Screen>
  ) : (
    <Navigate to='/auth/login' replace state={{ from: location }} />
  );
};
