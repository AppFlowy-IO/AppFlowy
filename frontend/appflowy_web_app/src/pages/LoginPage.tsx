import { AFConfigContext } from '@/components/main/app.hooks';
import { Login } from '@/components/login';
import React, { useContext, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';

function LoginPage () {
  const [search] = useSearchParams();
  const redirectTo = search.get('redirectTo') || '';
  const isAuthenticated = useContext(AFConfigContext)?.isAuthenticated || false;

  useEffect(() => {
    if (isAuthenticated && redirectTo && decodeURIComponent(redirectTo) !== window.location.href) {
      window.location.href = decodeURIComponent(redirectTo);
    }
  }, [isAuthenticated, redirectTo]);
  return (
    <div className={'bg-body flex h-screen w-screen items-center justify-center'}>
      <Login redirectTo={redirectTo} />
    </div>
  );
}

export default LoginPage;
