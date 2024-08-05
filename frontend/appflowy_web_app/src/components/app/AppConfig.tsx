import { clearData } from '@/application/db';
import { EventType, on } from '@/application/session';
import { isTokenValid } from '@/application/session/token';
import { useAppLanguage } from '@/components/app/useAppLanguage';
import { LoginModal } from '@/components/login';
import { useSnackbar } from 'notistack';
import React, { createContext, useCallback, useEffect, useState } from 'react';
import { AFService, AFServiceConfig } from '@/application/services/services.type';
import { getService } from '@/application/services';
import { InfoSnackbarProps } from '@/components/_shared/notify';
import { User } from '@/application/types';

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
      currentUser?: User;
      openLoginModal: (redirectTo?: string) => void;
    }
  | undefined
>(undefined);

function AppConfig({ children }: { children: React.ReactNode }) {
  const [appConfig] = useState<AFServiceConfig>(defaultConfig);
  const [service, setService] = useState<AFService>();
  const [isAuthenticated, setIsAuthenticated] = React.useState<boolean>(isTokenValid());
  const [currentUser, setCurrentUser] = React.useState<User>();
  const [loginOpen, setLoginOpen] = React.useState(false);
  const [loginCompletedRedirectTo, setLoginCompletedRedirectTo] = React.useState<string>('');

  const openLoginModal = useCallback((redirectTo?: string) => {
    setLoginOpen(true);
    setLoginCompletedRedirectTo(redirectTo || '');
  }, []);

  useEffect(() => {
    return on(EventType.SESSION_VALID, () => {
      setIsAuthenticated(true);
    });
  }, []);

  useEffect(() => {
    if (!isAuthenticated) {
      setCurrentUser(undefined);
      return;
    }

    void (async () => {
      if (!service) return;
      try {
        const user = await service.getCurrentUser();

        setCurrentUser(user);
      } catch (e) {
        console.error(e);
      }
    })();
  }, [isAuthenticated, service]);

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

      info: (props: InfoSnackbarProps) => {
        enqueueSnackbar(props.message, props);
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
        currentUser,
        openLoginModal,
      }}
    >
      {children}
      {loginOpen && (
        <LoginModal
          redirectTo={loginCompletedRedirectTo}
          open={loginOpen}
          onClose={() => {
            setLoginOpen(false);
          }}
        />
      )}
    </AFConfigContext.Provider>
  );
}

export default AppConfig;
