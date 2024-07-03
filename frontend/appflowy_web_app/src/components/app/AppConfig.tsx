import { useAppLanguage } from '@/components/app/useAppLanguage';
import { useSnackbar } from 'notistack';
import React, { createContext, useEffect, useState } from 'react';
import { AFService, AFServiceConfig } from '@/application/services/services.type';
import { getService } from '@/application/services';

const hostName = window.location.hostname;
const isProd = !hostName.includes('localhost');
const isBeta = isProd && hostName.includes('beta');
const isTest = isProd && hostName.includes('test');
const baseAPIHost = isProd
  ? isBeta
    ? 'beta.appflowy.cloud'
    : isTest
    ? 'test.appflowy.cloud'
    : 'beta.appflowy.cloud'
  : 'test.appflowy.cloud';
const baseURL = `https://${baseAPIHost}`;
const gotrueURL = `${baseURL}/gotrue`;

const defaultConfig: AFServiceConfig = {
  cloudConfig: {
    baseURL,
    gotrueURL,
    wsURL: `wss://${baseAPIHost}/ws/v1`,
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

  const { enqueueSnackbar, closeSnackbar } = useSnackbar();

  useEffect(() => {
    window.toast = {
      success: (message: string) => {
        enqueueSnackbar(message, { variant: 'success' });
      },
      error: (message: string) => {
        console.log('error', message);
        enqueueSnackbar(message, { variant: 'error' });
      },
      warning: (message: string) => {
        enqueueSnackbar(message, { variant: 'warning' });
      },
      default: (message: string) => {
        enqueueSnackbar(message, { variant: 'default' });
      },
      info: (message: string) => {
        enqueueSnackbar(message, { variant: 'info' });
      },

      clear: () => {
        closeSnackbar();
      },
    };
  }, [closeSnackbar, enqueueSnackbar]);

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
