import React from 'react';
import { useAppSelector } from '$app/stores/store';
import { ThemeMode } from '$app/interfaces';
import { AppflowyLogoDark } from '$app/components/_shared/svg/AppflowyLogoDark';
import { AppflowyLogoLight } from '$app/components/_shared/svg/AppflowyLogoLight';
import CollapseMenuButton from '$app/components/layout/CollapseMenuButton';
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
          transition: isResizing ? 'none' : 'width 150ms cubic-bezier(0.4, 0, 0.2, 1)',
        }}
        className={'relative h-screen select-none overflow-hidden'}
      >
        <div className={'flex h-[100vh] flex-col overflow-hidden border-r border-line-divider bg-bg-base'}>
          <div className={'flex h-[64px] justify-between px-6 py-5'}>
            {isDark ? <AppflowyLogoDark /> : <AppflowyLogoLight />}
            <CollapseMenuButton />
          </div>
          <div className={'flex h-[36px] items-center'}>
            <UserInfo />
          </div>

          <div
            style={{
              height: 'calc(100% - 64px - 36px)',
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
