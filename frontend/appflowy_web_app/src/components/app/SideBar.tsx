import { UIVariant } from '@/application/types';
import { OutlineDrawer } from '@/components/_shared/outline';
import Outline from '@/components/_shared/outline/Outline';
import { AppContext, useAppOutline, useAppViewId } from '@/components/app/app.hooks';
import React, { Suspense, useContext, lazy } from 'react';
import { Favorite } from '@/components/app/favorite';
import { Workspaces } from '@/components/app/workspaces';

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
  const outline = useAppOutline();

  const viewId = useAppViewId();
  const navigateToView = useContext(AppContext)?.toView;
  const rendered = useContext(AppContext)?.rendered;

  return (
    <OutlineDrawer
      onResizeWidth={onResizeDrawerWidth}
      width={drawerWidth}
      open={drawerOpened}
      onClose={() => toggleOpenDrawer(false)}
      header={<Workspaces />}
    >
      <div className={'flex w-full flex-1 flex-col'}>
        <Favorite />
        <Outline
          variant={UIVariant.App}
          navigateToView={navigateToView}
          selectedViewId={viewId}
          width={drawerWidth}
          outline={outline}
        />
        {rendered && <Suspense><SideBarBottom /></Suspense>}

      </div>
    </OutlineDrawer>
  );
}

export default SideBar;