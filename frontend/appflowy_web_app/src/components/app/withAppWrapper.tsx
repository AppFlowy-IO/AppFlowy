import { ErrorBoundary } from 'react-error-boundary';
import { ErrorHandlerPage } from 'src/components/error/ErrorHandlerPage';
import AppTheme from '@/components/app/AppTheme';
import AppConfig from '@/components/app/AppConfig';
import { Suspense, useEffect } from 'react';
import { SnackbarProvider, useSnackbar } from 'notistack';

export default function withAppWrapper(Component: React.FC): React.FC {
  return function AppWrapper(): JSX.Element {
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
        info: (message: string) => {
          enqueueSnackbar(message, { variant: 'info' });
        },

        clear: () => {
          closeSnackbar();
        },
      };
    }, [closeSnackbar, enqueueSnackbar]);
    return (
      <AppTheme>
        <ErrorBoundary FallbackComponent={ErrorHandlerPage}>
          <SnackbarProvider
            anchorOrigin={{
              vertical: 'top',
              horizontal: 'center',
            }}
            preventDuplicate
          >
            <AppConfig>
              <Suspense>
                <Component />
              </Suspense>
            </AppConfig>
          </SnackbarProvider>
        </ErrorBoundary>
      </AppTheme>
    );
  };
}
