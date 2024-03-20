import React, { ReactNode, useEffect, useMemo } from 'react';
import SideBar from '$app/components/layout/side_bar/SideBar';
import TopBar from '$app/components/layout/top_bar/TopBar';
import { useAppSelector } from '$app/stores/store';
import './layout.scss';
import { AFScroller } from '../_shared/scroller';
import { useNavigate } from 'react-router-dom';
import { pageTypeMap } from '$app_reducers/pages/slice';
import { useShortcuts } from '$app/components/layout/Layout.hooks';

function Layout({ children }: { children: ReactNode }) {
  const { isCollapsed, width } = useAppSelector((state) => state.sidebar);
  const currentUser = useAppSelector((state) => state.currentUser);
  const navigate = useNavigate();
  const { id: latestOpenViewId, layout } = useMemo(
    () =>
      currentUser?.workspaceSetting?.latestView || {
        id: undefined,
        layout: undefined,
      },
    [currentUser?.workspaceSetting?.latestView]
  );

  const onKeyDown = useShortcuts();

  useEffect(() => {
    window.addEventListener('keydown', onKeyDown);
    return () => {
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [onKeyDown]);

  useEffect(() => {
    if (latestOpenViewId) {
      const pageType = pageTypeMap[layout];

      navigate(`/page/${pageType}/${latestOpenViewId}`);
    }
  }, [latestOpenViewId, navigate, layout]);
  return (
    <>
      <div className='flex h-screen w-[100%] select-none text-sm text-text-title'>
        <SideBar />
        <div
          className='flex flex-1 select-none flex-col bg-bg-body'
          style={{
            width: isCollapsed ? '100%' : `calc(100% - ${width}px)`,
          }}
        >
          <TopBar />
          <AFScroller
            overflowXHidden
            style={{
              height: 'calc(100vh - 64px)',
            }}
            className={'appflowy-layout appflowy-scroll-container select-none'}
          >
            {children}
          </AFScroller>
        </div>
      </div>
    </>
  );
}

export default Layout;
