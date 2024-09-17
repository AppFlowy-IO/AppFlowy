import { AuthLayout } from '@/components/app/AuthLayout';
import RecordNotFound from '@/components/error/RecordNotFound';
import AppPage from '@/pages/AppPage';
import TrashPage from '@/pages/TrashPage';
import React from 'react';
import { Route, Routes } from 'react-router-dom';

function AppRouter () {
  return (
    <Routes>
      <Route element={<AuthLayout />}>
        <Route
          index element={<RecordNotFound noContent />}
        />
        <Route path={':workspaceId'} element={<AppPage />} />
        <Route path={':workspaceId/:viewId'} element={<AppPage />} />
        <Route path={'trash'} element={<TrashPage />} />
      </Route>
    </Routes>
  );
}

export default AppRouter;