import { AppProvider } from '@/components/app/app.hooks';
import MainLayout from '@/components/app/MainLayout';
import { getPlatform } from '@/utils/platform';
import React, { memo } from 'react';
import MobileMainLayout from '@/components/app/MobileMainLayout';

export function AuthLayout () {
  const isMobile = getPlatform().isMobile;

  return (
    <AppProvider>
      {isMobile ? <MobileMainLayout /> : <MainLayout />}
    </AppProvider>
  );
}

export default memo(AuthLayout);