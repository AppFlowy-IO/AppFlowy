import { FolderProvider } from '@/components/_shared/context-provider/FolderProvider';
import Header from '@/components/layout/Header';
import { AFScroller } from '@/components/_shared/scroller';
import { useLayout } from '@/components/layout/Layout.hooks';
import React from 'react';
import './layout.scss';
import { ReactComponent as Logo } from '@/assets/logo.svg';

function Layout({ children }: { children: React.ReactNode }) {
  const { folder, handleNavigateToView, crumbs, setCrumbs } = useLayout();

  if (!folder)
    return (
      <div className={'flex h-screen w-screen items-center justify-center'}>
        <Logo className={'h-20 w-20'} />
      </div>
    );

  return (
    <FolderProvider setCrumbs={setCrumbs} crumbs={crumbs} onNavigateToView={handleNavigateToView} folder={folder}>
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
    </FolderProvider>
  );
}

export default Layout;
