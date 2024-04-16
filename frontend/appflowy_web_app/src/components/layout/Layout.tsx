import Header from '@/components/layout/Header';
import { AFScroller } from '@/components/_shared/scroller';
import React from 'react';

function Layout({ children }: { children: React.ReactNode }) {
  return (
    <div>
      <Header />
      <AFScroller
        overflowXHidden
        style={{
          height: 'calc(100vh - 64px)',
        }}
        className={'appflowy-layout appflowy-scroll-container'}
      >
        {children}
      </AFScroller>
    </div>
  );
}

export default Layout;
