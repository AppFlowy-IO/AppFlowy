import React from 'react';
import { Outlet } from 'react-router-dom';
import Layout from '@/components/layout/Layout';
import Welcome from './Welcome';

function SplashScreen({
  isAuthenticated,
}: {
  isAuthenticated: boolean;
}) {
  if (isAuthenticated) {
    return (
      <Layout>
        <Outlet/>
      </Layout>
    );
  } else {
    return <Welcome/>;
  }
}

export default SplashScreen;