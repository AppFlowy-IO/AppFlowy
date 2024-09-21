import { AppProvider } from '@/components/app/app.hooks';
import MainLayout from '@/components/app/MainLayout';
import React, { memo } from 'react';

export function AuthLayout () {
  return (
    <AppProvider>
      <MainLayout />
    </AppProvider>
  );
}

export default memo(AuthLayout);