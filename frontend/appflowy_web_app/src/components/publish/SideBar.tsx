import { usePublishContext } from '@/application/publish';
import { UIVariant } from '@/application/types';
import { OutlineDrawer } from '@/components/_shared/outline';
import Outline from '@/components/_shared/outline/Outline';
import React from 'react';

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
  const outline = usePublishContext()?.outline;

  const viewId = usePublishContext()?.viewMeta?.view_id;
  const navigateToView = usePublishContext()?.toView;

  return (
    <OutlineDrawer
      variant={UIVariant.Publish}
      onResizeWidth={onResizeDrawerWidth} width={drawerWidth} open={drawerOpened}
      onClose={() => toggleOpenDrawer(false)}
    >
      <Outline
        variant={UIVariant.Publish}
        navigateToView={navigateToView}
        selectedViewId={viewId} width={drawerWidth}
        outline={outline}
      />
    </OutlineDrawer>
  );
}

export default SideBar;