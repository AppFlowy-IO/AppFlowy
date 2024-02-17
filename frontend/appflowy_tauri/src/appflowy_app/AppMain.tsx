import React from 'react';
import { Route, Routes } from 'react-router-dom';
import { ProtectedRoutes } from '$app/components/auth/ProtectedRoutes';
import { DatabasePage } from '$app/views/DatabasePage';

import { ThemeProvider } from '@mui/material';
import { useUserSetting } from '$app/AppMain.hooks';
import TrashPage from '$app/views/TrashPage';
import DocumentPage from '$app/views/DocumentPage';

function AppMain() {
  const { muiTheme } = useUserSetting();

  return (
    <ThemeProvider theme={muiTheme}>
      <Routes>
        <Route path={'/'} element={<ProtectedRoutes />}>
          <Route path={'/page/document/:id'} element={<DocumentPage />} />
          <Route path={'/page/grid/:id'} element={<DatabasePage />} />
          <Route path={'/trash'} id={'trash'} element={<TrashPage />} />
        </Route>
      </Routes>
    </ThemeProvider>
  );
}

export default AppMain;
