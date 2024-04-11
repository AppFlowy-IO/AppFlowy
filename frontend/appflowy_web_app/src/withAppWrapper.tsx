import { Provider } from 'react-redux';
import { store } from './stores/store';
import { ErrorBoundary } from 'react-error-boundary';
import { ErrorHandlerPage } from './components/error/ErrorHandlerPage';
import AppTheme from '@/AppTheme';
import { Toaster } from 'react-hot-toast';
import AppConfig from '@/AppConfig';
import { Suspense } from 'react';

export default function withAppWrapper (Component: React.FC): React.FC {
  return function AppWrapper (): JSX.Element {
    return (
      <Provider store={store}>
        <AppTheme>
          <ErrorBoundary FallbackComponent={ErrorHandlerPage}>
            <AppConfig>
              <Suspense>
                <Component />
                <Toaster />
              </Suspense>
            </AppConfig>
          </ErrorBoundary>
        </AppTheme>
      </Provider>
    );
  };
}