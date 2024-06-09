import React from 'react';
import { Outlet } from 'react-router-dom';
import Layout from '@/components/layout/Layout';

function SplashScreen () {

  return (
    <Layout>
      <Outlet/>
    </Layout>
  );
}

export default SplashScreen;