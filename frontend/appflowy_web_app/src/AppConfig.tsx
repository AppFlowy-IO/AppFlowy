import React, { createContext, useEffect, useMemo, useState } from 'react';
import { AFServiceConfig, AFService } from '@/application/services/services.type';
import { getService } from '@/application/services';

export const AFConfigContext = createContext<
  | {
      service: AFService | undefined;
    }
  | undefined
>(undefined);

const defaultConfig: AFServiceConfig = {
  cloudConfig: {
    baseURL: import.meta.env.DEV
      ? import.meta.env.AF_BASE_URL || 'https://test.appflowy.cloud'
      : 'https://beta.appflowy.cloud',
    gotrueURL: import.meta.env.DEV
      ? import.meta.env.AF_GOTRUE_URL || 'https://test.appflowy.cloud/gotrue'
      : 'https://beta.appflowy.cloud/gotrue',
    wsURL: import.meta.env.DEV
      ? import.meta.env.AF_WS_URL || 'wss://test.appflowy.cloud/ws/v1'
      : 'wss://beta.appflowy.cloud/ws/v1',
  },
};

function AppConfig({ children }: { children: React.ReactNode }) {
  const [serviceConfig, setServiceConfig] = useState<AFServiceConfig | undefined>(defaultConfig);
  const [service, setService] = useState<AFService>();

  console.log('serviceConfig', import.meta.env);
  useEffect(() => {
    void (async () => {
      if (!serviceConfig) return;
      setService(await getService(serviceConfig));
    })();
  }, [serviceConfig]);

  const config = useMemo(
    () => ({
      service,
    }),
    [service]
  );

  return <AFConfigContext.Provider value={config}>{children}</AFConfigContext.Provider>;
}

export default AppConfig;
