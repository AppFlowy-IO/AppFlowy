import { Login } from '@/components/login';
import React, { useContext, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { AFConfigContext } from '@/components/app/AppConfig';

function LoginPage() {
  const [search] = useSearchParams();
  const redirectTo = search.get('redirectTo') || '';
  const isAuthenticated = useContext(AFConfigContext)?.isAuthenticated || false;

  useEffect(() => {
    if (isAuthenticated && redirectTo && encodeURIComponent(redirectTo) !== window.location.href) {
      window.location.href = redirectTo;
    }
  }, [isAuthenticated, redirectTo]);
  return (
    <div className={'bg-body flex h-screen w-screen items-center justify-center'}>
      <Login redirectTo={redirectTo} />
    </div>
  );
}

export default LoginPage;
