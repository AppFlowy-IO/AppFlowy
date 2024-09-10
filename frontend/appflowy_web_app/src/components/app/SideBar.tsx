import { OutlineDrawer } from '@/components/_shared/outline';
import Outline from '@/components/_shared/outline/Outline';
import { AppContext, useAppOutline, useAppViewId } from '@/components/app/app.hooks';
import React, { useContext } from 'react';

interface SideBarProps {
  drawerWidth: number;
  drawerOpened: boolean;
  toggleOpenDrawer: (status: boolean) => void;
  onResizeDrawerWidth: (width: number) => void;
}

function SideBar ({
  drawerWidth, drawerOpened, toggleOpenDrawer,
  onResizeDrawerWidth,
}: SideBarProps) {
  const outline = useAppOutline();

  const viewId = useAppViewId();
  const navigateToView = useContext(AppContext)?.toView;

  return (
    <OutlineDrawer onResizeWidth={onResizeDrawerWidth} width={drawerWidth} open={drawerOpened}
                   onClose={() => toggleOpenDrawer(false)}
    >
      <Outline navigateToView={navigateToView} selectedViewId={viewId} width={drawerWidth} outline={outline} />
    </OutlineDrawer>
  );
}

export default SideBar;