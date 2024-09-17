import CustomSnackbar from '@/components/_shared/notify/CustomSnackbar';
import { ErrorBoundary } from 'react-error-boundary';
import { ErrorHandlerPage } from 'src/components/error/ErrorHandlerPage';
import AppTheme from '@/components/main/AppTheme';
import AppConfig from '@/components/main/AppConfig';
import { Suspense } from 'react';
import { SnackbarProvider } from 'notistack';
import { styled } from '@mui/material';
import { InfoSnackbar } from '../_shared/notify';

const StyledSnackbarProvider = styled(SnackbarProvider)`
    &.notistack-MuiContent-default {
        background-color: var(--fill-toolbar);
    }

    &.notistack-MuiContent-info {
        background-color: var(--function-info);
    }

`;

export default function withAppWrapper (Component: React.FC): React.FC {
  return function AppWrapper (): JSX.Element {
    return (
      <AppTheme>
        <ErrorBoundary FallbackComponent={ErrorHandlerPage}>
          <StyledSnackbarProvider
            anchorOrigin={{
              vertical: 'top',
              horizontal: 'center',
            }}
            preventDuplicate
            Components={{
              info: InfoSnackbar,
              success: CustomSnackbar,
              error: CustomSnackbar,
              warning: CustomSnackbar,
              default: CustomSnackbar,
            }}
          >
            <AppConfig>
              <Suspense>
                <Component />
              </Suspense>
            </AppConfig>
          </StyledSnackbarProvider>
        </ErrorBoundary>
      </AppTheme>
    );
  };
}
