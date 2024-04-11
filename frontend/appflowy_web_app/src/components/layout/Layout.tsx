import Header from '@/components/layout/Header';
import React from 'react';

function Layout ({ children }: { children: React.ReactNode }) {

  return (
    <div>
      <Header />
      {children}
    </div>
  );
}

export default Layout;
