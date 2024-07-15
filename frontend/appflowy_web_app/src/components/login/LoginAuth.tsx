import { AFConfigContext } from '@/components/app/AppConfig';
import { CircularProgress } from '@mui/material';
import { useContext, useEffect, useState } from 'react';

function LoginAuth() {
  const service = useContext(AFConfigContext)?.service;
  const [loading, setLoading] = useState<boolean>(false);

  useEffect(() => {
    void (async () => {
      setLoading(true);
      try {
        await service?.loginAuth(window.location.href);
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    })();
  }, [service]);
  return loading ? (
    <div className={'flex h-screen w-screen items-center justify-center'}>
      <CircularProgress />
    </div>
  ) : null;
}

export default LoginAuth;
