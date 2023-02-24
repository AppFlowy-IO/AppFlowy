import { Routes, Route, BrowserRouter } from 'react-router-dom';

import { TestColors } from './components/TestColors/TestColors';
import TestApiButton from './components/TestApiButton/TestApiButton';
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

const App = () => {
  // const location = useLocation();

  // console.log(location);

  return (
    <BrowserRouter>
      <Provider store={store}>
        <Routes>
          <Route path={'/'} element={<ProtectedRoutes />}>
            <Route path={'/page/colors'} element={<TestColors />} />
            <Route path={'/page/api-test'} element={<TestApiButton />} />
            <Route path={'/page/document/:id'} element={<DocumentPage />} />
            <Route path={'/page/board/:id'} element={<BoardPage />} />
            <Route path={'/page/grid/:id'} element={<GridPage />} />
            <Route path={'/'} element={<Welcome />} />
          </Route>
          <Route path={'/auth/login'} element={<LoginPage />}></Route>
          <Route path={'/auth/signUp'} element={<SignUpPage />}></Route>
          <Route path={'/auth/confirm-account'} element={<ConfirmAccountPage />}></Route>
          <Route path={'*'}>Not Found</Route>
        </Routes>
      </Provider>
    </BrowserRouter>
  );
};

export default App;
