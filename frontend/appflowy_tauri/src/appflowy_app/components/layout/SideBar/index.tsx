import React from 'react';
import { useAppSelector } from '$app/stores/store';
import { ThemeMode } from '$app/interfaces';
import { AppflowyLogoDark } from '$app/components/_shared/svg/AppflowyLogoDark';
import { AppflowyLogoLight } from '$app/components/_shared/svg/AppflowyLogoLight';
import CollapseButton from '$app/components/layout/CollapseMenuButton';
import Resizer from '$app/components/layout/SideBar/Resizer';
import UserInfo from '$app/components/layout/SideBar/UserInfo';
import WorkspaceManager from '$app/components/layout/WorkspaceManager';

function SideBar() {
  const { isCollapsed, width, isResizing } = useAppSelector((state) => state.sidebar);
  const isDark = useAppSelector((state) => state.currentUser?.userSetting?.themeMode === ThemeMode.Dark);

  return (
    <>
      <div
        style={{
          width: isCollapsed ? 0 : width,
          transition: isResizing ? 'none' : 'minWidth 0.2s ease-in-out',
        }}
        className={'relative h-screen select-none overflow-hidden'}
      >
        <div className={'flex h-[100vh] flex-col overflow-hidden border-r border-line-divider bg-bg-base'}>
          <div className={'flex h-[64px] justify-between px-6 py-5'}>
            {isDark ? <AppflowyLogoDark /> : <AppflowyLogoLight />}
            <CollapseButton />
          </div>
          <div className={'flex h-[48px] items-center'}>
            <UserInfo />
          </div>

          <div
            style={{
              height: 'calc(100% - 64px - 48px)',
            }}
          >
            <WorkspaceManager />
          </div>
        </div>
      </div>
      <Resizer />
    </>
  );
}

export default SideBar;
