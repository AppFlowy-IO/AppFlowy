import { useOutlineDrawer } from '@/components/_shared/outline/outline.hooks';
import { AFScroller } from '@/components/_shared/scroller';
import { AppProvider } from '@/components/app/app.hooks';
import { AppHeader } from '@/components/app/header';
import Main from '@/components/app/Main';
import SideBar from '@/components/app/SideBar';
import React, { memo, useMemo } from 'react';

export function AuthLayout () {
  const {
    drawerOpened,
    drawerWidth,
    setDrawerWidth,
    toggleOpenDrawer,
  } = useOutlineDrawer();

  const main = useMemo(() => {
    return <Main />;
  }, []);

  return (
    <AppProvider>
      <div className={'h-screen w-screen'}>
        <AFScroller
          overflowXHidden
          overflowYHidden={false}
          style={{
            transform: drawerOpened ? `translateX(${drawerWidth}px)` : 'none',
            width: drawerOpened ? `calc(100% - ${drawerWidth}px)` : '100%',
            transition: 'width 0.2s ease-in-out, transform 0.2s ease-in-out',
          }}
          className={'appflowy-layout flex flex-col appflowy-scroll-container h-full'}
        >
          <AppHeader
            onOpenDrawer={() => {
              toggleOpenDrawer(true);
            }}
            drawerWidth={drawerWidth}
            onCloseDrawer={() => {
              toggleOpenDrawer(false);
            }}
            openDrawer={drawerOpened}
          />
          {main}

        </AFScroller>
        {drawerOpened &&
          <SideBar
            onResizeDrawerWidth={setDrawerWidth}
            drawerWidth={drawerWidth} drawerOpened={drawerOpened}
            toggleOpenDrawer={toggleOpenDrawer}
          />
        }
      </div>
    </AppProvider>
  );
}

export default memo(AuthLayout);