import React, { createContext, useEffect, useMemo, useState } from 'react';
import { AFService } from '@/application/services/services.type';
import { getService } from '@/application/services';
import { useAppSelector } from '@/stores/store';

export const AFConfigContext = createContext<
  | {
  service: AFService | undefined;
}
  | undefined
>(undefined);

function AppConfig ({ children }: { children: React.ReactNode }) {
  const appConfig = useAppSelector((state) => state.app.appConfig);
  const [service, setService] = useState<AFService>();

  useEffect(() => {
    void (async () => {
      if (!appConfig) return;
      setService(await getService(appConfig));
    })();
  }, [appConfig]);

  const config = useMemo(
    () => ({
      service,
    }),
    [service],
  );

  return <AFConfigContext.Provider value={config}>{children}</AFConfigContext.Provider>;
}

export default AppConfig;
