import React from 'react';
import { useAppSelector } from '$app/stores/store';
import { AppflowyLogoDark } from '$app/components/_shared/svg/AppflowyLogoDark';
import { AppflowyLogoLight } from '$app/components/_shared/svg/AppflowyLogoLight';
import CollapseMenuButton from '$app/components/layout/collapse_menu_button/CollapseMenuButton';
import Resizer from '$app/components/layout/side_bar/Resizer';
import UserInfo from '$app/components/layout/side_bar/UserInfo';
import WorkspaceManager from '$app/components/layout/workspace_manager/WorkspaceManager';

function SideBar() {
  const { isCollapsed, width, isResizing } = useAppSelector((state) => state.sidebar);
  const isDark = useAppSelector((state) => state.currentUser?.userSetting?.isDark);

  return (
    <>
      <div
        style={{
          width: isCollapsed ? 0 : width,
          transition: isResizing ? 'none' : 'width 250ms cubic-bezier(0.4, 0, 0.2, 1)',
        }}
        className={'relative h-screen overflow-hidden'}
      >
        <div className={'flex h-[100vh] flex-col overflow-hidden border-r border-line-divider bg-bg-base'}>
          <div className={'flex h-[64px] justify-between px-4 py-5'}>
            {isDark ? <AppflowyLogoDark /> : <AppflowyLogoLight />}
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
