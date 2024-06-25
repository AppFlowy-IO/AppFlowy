import { useAppLanguage } from '@/components/app/useAppLanguage';
import React, { createContext, useEffect, useState } from 'react';
import { AFService, AFServiceConfig } from '@/application/services/services.type';
import { getService } from '@/application/services';

const defaultConfig: AFServiceConfig = {
  cloudConfig: {
    baseURL: import.meta.env.AF_BASE_URL
      ? import.meta.env.AF_BASE_URL
      : import.meta.env.DEV
      ? 'https://test.appflowy.cloud'
      : 'https://beta.appflowy.cloud',
    gotrueURL: import.meta.env.AF_GOTRUE_URL
      ? import.meta.env.AF_GOTRUE_URL
      : import.meta.env.DEV
      ? 'https://test.appflowy.cloud/gotrue'
      : 'https://beta.appflowy.cloud/gotrue',
    wsURL: import.meta.env.AF_WS_URL
      ? import.meta.env.AF_WS_URL
      : import.meta.env.DEV
      ? 'wss://test.appflowy.cloud/ws/v1'
      : 'wss://beta.appflowy.cloud/ws/v1',
  },
};

export const AFConfigContext = createContext<
  | {
      service: AFService | undefined;
    }
  | undefined
>(undefined);

function AppConfig({ children }: { children: React.ReactNode }) {
  const [appConfig] = useState<AFServiceConfig>(defaultConfig);
  const [service, setService] = useState<AFService>();

  useAppLanguage();

  useEffect(() => {
    void (async () => {
      if (!appConfig) return;
      setService(await getService(appConfig));
    })();
  }, [appConfig]);

  return (
    <AFConfigContext.Provider
      value={{
        service,
      }}
    >
      {children}
    </AFConfigContext.Provider>
  );
}

export default AppConfig;
