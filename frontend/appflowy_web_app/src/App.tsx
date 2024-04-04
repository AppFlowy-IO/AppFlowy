import { BrowserRouter, Route, Routes } from 'react-router-dom';
import { Provider } from 'react-redux';
import { store } from './stores/store';
import { ErrorBoundary } from 'react-error-boundary';
import { ErrorHandlerPage } from './components/error/ErrorHandlerPage';
import '@/i18n/config';
import AppTheme from '@/AppTheme';
import { Toaster } from 'react-hot-toast';
import ProtectedRoutes from '@/components/auth/ProtectedRoutes';
import AppConfig from '@/AppConfig';

function App() {
  return (
    <BrowserRouter>
      <Provider store={store}>
        <AppTheme>
          <ErrorBoundary FallbackComponent={ErrorHandlerPage}>
            <AppConfig>
              <Routes>
                <Route path={'/'} element={<ProtectedRoutes />}>
                  {/*<Route path={'/page/document/:id'} element={<DocumentPage />} />*/}
                  {/*<Route path={'/page/grid/:id'} element={<DatabasePage />} />*/}
                  {/*<Route path={'/trash'} id={'trash'} element={<TrashPage />} />*/}
                </Route>
              </Routes>
              <Toaster />
            </AppConfig>
          </ErrorBoundary>
        </AppTheme>
      </Provider>
    </BrowserRouter>
  );
}

export default App;
