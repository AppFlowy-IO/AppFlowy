import { clearData } from '@/application/db';
import { getService } from '@/application/services';
import { AFService, AFServiceConfig } from '@/application/services/services.type';
import { EventType, on } from '@/application/session';
import { isTokenValid } from '@/application/session/token';
import { User } from '@/application/types';
import { InfoSnackbarProps } from '@/components/_shared/notify';
import { AFConfigContext, defaultConfig } from '@/components/app/app.hooks';
import { useAppLanguage } from '@/components/app/useAppLanguage';
import { LoginModal } from '@/components/login';
import { createHotkey, HOT_KEY_NAME } from '@/utils/hotkeys';
import { useSnackbar } from 'notistack';
import React, { useCallback, useEffect, useState } from 'react';

function AppConfig ({ children }: { children: React.ReactNode }) {
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
        enqueueSnackbar(message, { variant: 'error' });
      },
      warning: (message: string) => {
        enqueueSnackbar(message, { variant: 'warning', autoHideDuration: 500000000000 });
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
      switch (true) {
        case createHotkey(HOT_KEY_NAME.CLEAR_CACHE)(e):
          e.stopPropagation();
          e.preventDefault();
          void clearData().then(() => {
            window.location.reload();
          });
          break;
        default:
          break;
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
