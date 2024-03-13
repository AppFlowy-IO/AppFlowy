import React, { useEffect, useRef } from 'react';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { ReactComponent as AppflowyLogoDark } from '$app/assets/dark-logo.svg';
import { ReactComponent as AppflowyLogoLight } from '$app/assets/light-logo.svg';
import CollapseMenuButton from '$app/components/layout/collapse_menu_button/CollapseMenuButton';
import Resizer from '$app/components/layout/side_bar/Resizer';
import UserInfo from '$app/components/layout/side_bar/UserInfo';
import WorkspaceManager from '$app/components/layout/workspace_manager/WorkspaceManager';
import { ThemeMode } from '$app_reducers/current-user/slice';
import { sidebarActions } from '$app_reducers/sidebar/slice';

function SideBar() {
  const { isCollapsed, width, isResizing } = useAppSelector((state) => state.sidebar);
  const dispatch = useAppDispatch();

  const themeMode = useAppSelector((state) => state.currentUser?.userSetting?.themeMode);
  const isDark =
    themeMode === ThemeMode.Dark ||
    (themeMode === ThemeMode.System && window.matchMedia('(prefers-color-scheme: dark)').matches);

  const lastCollapsedRef = useRef(isCollapsed);

  useEffect(() => {
    const handleResize = () => {
      const width = window.innerWidth;

      if (width <= 800 && !isCollapsed) {
        lastCollapsedRef.current = false;
        dispatch(sidebarActions.setCollapse(true));
      } else if (width > 800 && !lastCollapsedRef.current) {
        lastCollapsedRef.current = true;
        dispatch(sidebarActions.setCollapse(false));
      }
    };

    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
    };
  }, [dispatch, isCollapsed]);
  return (
    <>
      <div
        style={{
          width: isCollapsed ? 0 : width,
          transition: isResizing ? 'none' : 'width 350ms ease',
        }}
        className={'relative h-screen overflow-hidden'}
      >
        <div className={'flex h-[100vh] flex-col overflow-hidden border-r border-line-divider bg-bg-base'}>
          <div className={'flex h-[64px] justify-between px-4 py-5'}>
            {isDark ? (
              <AppflowyLogoDark className={'h-6 w-[103px]'} />
            ) : (
              <AppflowyLogoLight className={'h-6 w-[103px]'} />
            )}
            <CollapseMenuButton />
          </div>
          <div className={'flex h-[36px] items-center'}>
            <UserInfo />
          </div>
          <div className={'flex-1 overflow-hidden'}>
            <WorkspaceManager />
          </div>
        </div>
      </div>
      <Resizer />
    </>
  );
}

export default SideBar;
