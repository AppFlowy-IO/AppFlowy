import { Routes, Route, BrowserRouter } from 'react-router-dom';

import { ColorPalette } from './components/tests/ColorPalette';
import { Provider } from 'react-redux';
import { store } from './stores/store';
import { DocumentPage } from './views/DocumentPage';
import { BoardPage } from './views/BoardPage';
import { GridPage } from './views/GridPage';
import { LoginPage } from './views/LoginPage';
import { ProtectedRoutes } from './components/auth/ProtectedRoutes';
import { SignUpPage } from './views/SignUpPage';
import { ConfirmAccountPage } from './views/ConfirmAccountPage';
import { ErrorHandlerPage } from './components/error/ErrorHandlerPage';
import initializeI18n from './stores/i18n/initializeI18n';
import { TestAPI } from './components/tests/TestAPI';
import { GetStarted } from './components/auth/GetStarted/GetStarted';
import { ErrorBoundary } from 'react-error-boundary';
import { AllIcons } from '$app/components/tests/AllIcons';

initializeI18n();

const App = () => {
  return (
    <BrowserRouter>
      <Provider store={store}>
        <ErrorBoundary FallbackComponent={ErrorHandlerPage}>
          <Routes>
            <Route path={'/'} element={<ProtectedRoutes />}>
              <Route path={'/page/all-icons'} element={<AllIcons />} />
              <Route path={'/page/colors'} element={<ColorPalette />} />
              <Route path={'/page/api-test'} element={<TestAPI />} />
              <Route path={'/page/document/:id'} element={<DocumentPage />} />
              <Route path={'/page/board/:id'} element={<BoardPage />} />
              <Route path={'/page/grid/:id'} element={<GridPage />} />
            </Route>
            <Route path={'/auth/login'} element={<LoginPage />}></Route>
            <Route path={'/auth/getStarted'} element={<GetStarted />}></Route>
            <Route path={'/auth/signUp'} element={<SignUpPage />}></Route>
            <Route path={'/auth/confirm-account'} element={<ConfirmAccountPage />}></Route>
          </Routes>
        </ErrorBoundary>
      </Provider>
    </BrowserRouter>
  );
};

export default App;
