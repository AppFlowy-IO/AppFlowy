import { OutlineDrawer } from '@/components/_shared/outline';
import NewPage from '@/components/app/view-actions/NewPage';
import React, { lazy } from 'react';
import { Favorite } from '@/components/app/favorite';
import { Workspaces } from '@/components/app/workspaces';
import Outline from 'src/components/app/outline/Outline';

const SideBarBottom = lazy(() => import('@/components/app/SideBarBottom'));

interface SideBarProps {
  drawerWidth: number;
  drawerOpened: boolean;
  toggleOpenDrawer: (status: boolean) => void;
  onResizeDrawerWidth: (width: number) => void;
}

function SideBar ({
  drawerWidth,
  drawerOpened,
  toggleOpenDrawer,
  onResizeDrawerWidth,
}: SideBarProps) {

  return (
    <OutlineDrawer
      onResizeWidth={onResizeDrawerWidth}
      width={drawerWidth}
      open={drawerOpened}
      onClose={() => toggleOpenDrawer(false)}
      header={<Workspaces />}
    >
      <div
        className={'flex w-full flex-1 flex-col'}
      >
        <Favorite />
        <NewPage />
        <Outline
          width={drawerWidth}
        />

        <SideBarBottom />
      </div>
    </OutlineDrawer>
  );
}

export default SideBar;