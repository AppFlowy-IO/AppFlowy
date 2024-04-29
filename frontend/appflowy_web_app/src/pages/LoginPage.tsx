import React, { useEffect } from 'react';
import Welcome from '@/components/auth/Welcome';
import { useNavigate } from 'react-router-dom';
import { useAppSelector } from '@/stores/store';

function LoginPage () {
  const currentUser = useAppSelector((state) => state.currentUser);
  const navigate = useNavigate();

  useEffect(() => {
    if (currentUser.isAuthenticated) {
      const redirect = new URLSearchParams(window.location.search).get('redirect');

      navigate(`${redirect || ''}`);
    }
  }, [currentUser, navigate]);
  return (
    <Welcome />
  );
}

export default LoginPage;