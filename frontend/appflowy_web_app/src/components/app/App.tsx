import AfChatPage from '@/pages/AFChatPage';
import FolderPage from '@/pages/FolderPage';
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import ProtectedRoutes from '@/components/auth/ProtectedRoutes';
import LoginPage from '@/pages/LoginPage';
import ProductPage from '@/pages/ProductPage';
import withAppWrapper from '@/components/app/withAppWrapper';

const AppMain = withAppWrapper(() => {
  return (
    <Routes>
      <Route path={'/'} element={<ProtectedRoutes />}>
        <Route path={'/view/:workspaceId'} element={<FolderPage />} />
        <Route path={'/view/:workspaceId/:objectId'} element={<ProductPage />} />
      </Route>
      <Route path={'/login'} element={<LoginPage />} />
      <Route path={'/chat'} element={<AfChatPage />} />
    </Routes>
  );
});

function App() {
  return (
    <BrowserRouter>
      <AppMain />
    </BrowserRouter>
  );
}

export default App;
