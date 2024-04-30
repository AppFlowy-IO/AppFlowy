import React, { useEffect } from 'react';
import Welcome from '@/components/auth/Welcome';
import { useNavigate } from 'react-router-dom';
import { useAppSelector } from '@/stores/store';

function LoginPage() {
  const currentUser = useAppSelector((state) => state.currentUser);
  const navigate = useNavigate();

  useEffect(() => {
    if (currentUser.isAuthenticated) {
      const redirect = new URLSearchParams(window.location.search).get('redirect');
      const workspaceId = currentUser.user?.workspaceId;

      if (!redirect || redirect === '/') {
        return navigate(`/workspace/${workspaceId}`);
      }

      navigate(`${redirect}`);
    }
  }, [currentUser, navigate]);
  return <Welcome />;
}

export default LoginPage;
