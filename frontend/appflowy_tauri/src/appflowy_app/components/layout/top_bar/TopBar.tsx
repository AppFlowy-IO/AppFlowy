import React from 'react';
import CollapseMenuButton from '$app/components/layout/collapse_menu_button/CollapseMenuButton';
import { useAppSelector } from '$app/stores/store';
import Breadcrumb from '$app/components/layout/bread_crumb/BreadCrumb';
import DeletePageSnackbar from '$app/components/layout/top_bar/DeletePageSnackbar';

function TopBar() {
  const sidebarIsCollapsed = useAppSelector((state) => state.sidebar.isCollapsed);

  return (
    <div className={'appflowy-top-bar flex h-[64px] select-none border-b border-line-divider p-4'}>
      {sidebarIsCollapsed && (
        <div className={'mr-2 pt-[3px]'}>
          <CollapseMenuButton />
        </div>
      )}
      <div className={'flex flex-1 items-center justify-between'}>
        <div className={'flex-1'}>
          <Breadcrumb />
        </div>
      </div>
      <DeletePageSnackbar />
    </div>
  );
}

export default TopBar;
