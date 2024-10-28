import { AppProvider } from '@/components/app/app.hooks';
import MainLayout from '@/components/app/MainLayout';
import { getPlatform } from '@/utils/platform';
import React, { memo, Suspense } from 'react';

const MobileMainLayout = React.lazy(() => import('@/components/app/MobileMainLayout'));

export function AuthLayout () {
  const isMobile = getPlatform().isMobile;

  return (
    <AppProvider>
      {isMobile ? <Suspense><MobileMainLayout /></Suspense> : <MainLayout />}
    </AppProvider>
  );
}

export default memo(AuthLayout);