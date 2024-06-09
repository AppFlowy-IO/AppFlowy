import { useEffect } from 'react';
import { useDeepLink } from '@/components/tauri/tauri.hooks';

function TauriAuth() {
  const {
    onDeepLink,
  } = useDeepLink();

  useEffect(() => {
    void onDeepLink();
  }, [onDeepLink]);

  return null;
}

export default TauriAuth;