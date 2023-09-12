import React from 'react';
import { Route, Routes } from 'react-router-dom';
import { ProtectedRoutes } from '$app/components/auth/ProtectedRoutes';
import { AllIcons } from '$app/components/tests/AllIcons';
import { ColorPalette } from '$app/components/tests/ColorPalette';
import { TestAPI } from '$app/components/tests/TestAPI';
import { DocumentPage } from '$app/views/DocumentPage';
import { BoardPage } from '$app/views/BoardPage';
import { DatabasePage } from '$app/views/DatabasePage';
import { LoginPage } from '$app/views/LoginPage';
import { GetStarted } from '$app/components/auth/GetStarted/GetStarted';
import { SignUpPage } from '$app/views/SignUpPage';
import { ConfirmAccountPage } from '$app/views/ConfirmAccountPage';
import { ThemeProvider } from '@mui/material';
import { useUserSetting } from '$app/AppMain.hooks';
import { UserSettingControllerContext } from '$app/components/_shared/app-hooks/useUserSettingControllerContext';
import TrashPage from '$app/views/TrashPage';

function AppMain() {
  const { muiTheme, userSettingController } = useUserSetting();

  return (
    <UserSettingControllerContext.Provider value={userSettingController}>
      <ThemeProvider theme={muiTheme}>
        <Routes>
          <Route path={'/'} element={<ProtectedRoutes />}>
            <Route path={'/page/all-icons'} element={<AllIcons />} />
            <Route path={'/page/colors'} element={<ColorPalette />} />
            <Route path={'/page/api-test'} element={<TestAPI />} />
            <Route path={'/page/document/:id'} element={<DocumentPage />} />
            <Route path={'/page/board/:id'} element={<BoardPage />} />
            <Route path={'/page/grid/:id'} element={<DatabasePage />} />
            <Route path={'/trash'} id={'trash'} element={<TrashPage />} />
          </Route>
          <Route path={'/auth/login'} element={<LoginPage />}></Route>
          <Route path={'/auth/getStarted'} element={<GetStarted />}></Route>
          <Route path={'/auth/signUp'} element={<SignUpPage />}></Route>
          <Route path={'/auth/confirm-account'} element={<ConfirmAccountPage />}></Route>
        </Routes>
      </ThemeProvider>
    </UserSettingControllerContext.Provider>
  );
}

export default AppMain;
