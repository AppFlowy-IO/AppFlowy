import { clearData, db } from '@/application/db';
import { getService } from '@/application/services';
import { AFServiceConfig } from '@/application/services/services.type';
import { EventType, on } from '@/application/session';
import { getTokenParsed, isTokenValid } from '@/application/session/token';
import { InfoSnackbarProps } from '@/components/_shared/notify';
import { AFConfigContext, defaultConfig } from '@/components/main/app.hooks';
import { useAppLanguage } from '@/components/main/useAppLanguage';
import { LoginModal } from '@/components/login';
import { createHotkey, HOT_KEY_NAME } from '@/utils/hotkeys';
import { useLiveQuery } from 'dexie-react-hooks';
import { useSnackbar } from 'notistack';
import React, { Suspense, useCallback, useEffect, useMemo, useState } from 'react';

function AppConfig ({ children }: { children: React.ReactNode }) {
  const [appConfig] = useState<AFServiceConfig>(defaultConfig);
  const service = useMemo(() => getService(appConfig), [appConfig]);
  const [isAuthenticated, setIsAuthenticated] = React.useState<boolean>(isTokenValid());

  const userId = useMemo(() => {
    if (!isAuthenticated) return;
    return getTokenParsed()?.user?.id;
  }, [isAuthenticated]);

  const currentUser = useLiveQuery(
    async () => {
      if (!userId) return;
      return db.users.get(userId);
    }, [userId],
  );
  const [loginOpen, setLoginOpen] = React.useState(false);
  const [loginCompletedRedirectTo, setLoginCompletedRedirectTo] = React.useState<string>('');

  const openLoginModal = useCallback((redirectTo?: string) => {
    setLoginOpen(true);
    setLoginCompletedRedirectTo(redirectTo || window.location.href);
  }, []);

  useEffect(() => {
    return on(EventType.SESSION_VALID, () => {
      setIsAuthenticated(true);
    });
  }, []);

  useEffect(() => {
    if (!isAuthenticated) {
      return;
    }

    void (async () => {
      if (!service) return;
      try {
        await service.getCurrentUser();

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
        <Suspense>
          <LoginModal
            redirectTo={loginCompletedRedirectTo}
            open={loginOpen}
            onClose={() => {
              setLoginOpen(false);
            }}
          />
        </Suspense>

      )}
    </AFConfigContext.Provider>
  );
}

export default AppConfig;
