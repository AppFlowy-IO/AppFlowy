import { Routes, Route, BrowserRouter } from 'react-router-dom';

import { TestColors } from './components/TestColors/TestColors';
import { Welcome } from './views/Welcome';
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
import { TestAPI } from './components/TestApiButton/TestAPI';

initializeI18n();

const App = () => {
  return (
    <BrowserRouter>
      <Provider store={store}>
        <Routes>
          <Route path={'/'} element={<ProtectedRoutes />}>
            <Route path={'/page/colors'} element={<TestColors />} />
            <Route path={'/page/api-test'} element={<TestAPI />} />
            <Route path={'/page/document/:id'} element={<DocumentPage />} />
            <Route path={'/page/board/:id'} element={<BoardPage />} />
            <Route path={'/page/grid/:id'} element={<GridPage />} />
            <Route path={'/'} element={<Welcome />} />
          </Route>
          <Route path={'/auth/login'} element={<LoginPage />}></Route>
          <Route path={'/auth/signUp'} element={<SignUpPage />}></Route>
          <Route path={'/auth/confirm-account'} element={<ConfirmAccountPage />}></Route>
        </Routes>
        <ErrorHandlerPage></ErrorHandlerPage>
      </Provider>
    </BrowserRouter>
  );
};

export default App;
