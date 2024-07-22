import { clearData } from '@/application/db';
import { EventType, on } from '@/application/session';
import { isTokenValid } from '@/application/session/token';
import { useAppLanguage } from '@/components/app/useAppLanguage';
import { useSnackbar } from 'notistack';
import React, { createContext, useEffect, useState } from 'react';
import { AFService, AFServiceConfig } from '@/application/services/services.type';
import { getService } from '@/application/services';

const baseURL = import.meta.env.AF_BASE_URL || 'https://test.appflowy.cloud';
const gotrueURL = import.meta.env.AF_GOTRUE_URL || 'https://test.appflowy.cloud/gotrue';
const wsURL = import.meta.env.AF_WS_URL || 'wss://test.appflowy.cloud/ws/v1';

const defaultConfig: AFServiceConfig = {
  cloudConfig: {
    baseURL,
    gotrueURL,
    wsURL,
  },
};

export const AFConfigContext = createContext<
  | {
      service: AFService | undefined;
      isAuthenticated: boolean;
    }
  | undefined
>(undefined);

function AppConfig({ children }: { children: React.ReactNode }) {
  const [appConfig] = useState<AFServiceConfig>(defaultConfig);
  const [service, setService] = useState<AFService>();
  const [isAuthenticated, setIsAuthenticated] = React.useState<boolean>(isTokenValid());

  useEffect(() => {
    return on(EventType.SESSION_VALID, () => {
      setIsAuthenticated(true);
    });
  }, []);

  useEffect(() => {
    const handleStorageChange = (event: StorageEvent) => {
      if (event.key === 'token') setIsAuthenticated(isTokenValid());
    };

    window.addEventListener('storage', handleStorageChange);
    return () => {
      window.removeEventListener('storage', handleStorageChange);
    };
  }, []);
  useEffect(() => {
    return on(EventType.SESSION_INVALID, () => {
      setIsAuthenticated(false);
    });
  }, []);
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

  useEffect(() => {
    const handleClearData = (e: KeyboardEvent) => {
      if (e.key.toLowerCase() === 'r' && (e.ctrlKey || e.metaKey) && e.shiftKey) {
        e.stopPropagation();
        e.preventDefault();
        void clearData().then(() => {
          window.location.reload();
        });
      }
    };

    window.addEventListener('keydown', handleClearData);
    return () => {
      window.removeEventListener('keydown', handleClearData);
    };
  });

  return (
    <AFConfigContext.Provider
      value={{
        service,
        isAuthenticated,
      }}
    >
      {children}
    </AFConfigContext.Provider>
  );
}

export default AppConfig;
