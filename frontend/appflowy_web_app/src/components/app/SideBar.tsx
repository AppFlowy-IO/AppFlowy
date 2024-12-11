import { OutlineDrawer } from '@/components/_shared/outline';
import NewPage from '@/components/app/view-actions/NewPage';
import React, { lazy } from 'react';
import { Favorite } from '@/components/app/favorite';
import { Workspaces } from '@/components/app/workspaces';
import Outline from 'src/components/app/outline/Outline';
import { UIVariant } from '@/application/types';

const SideBarBottom = lazy(() => import('@/components/app/SideBarBottom'));

interface SideBarProps {
  drawerWidth: number;
  drawerOpened: boolean;
  toggleOpenDrawer: (status: boolean) => void;
  onResizeDrawerWidth: (width: number) => void;
}

function SideBar({
  drawerWidth,
  drawerOpened,
  toggleOpenDrawer,
  onResizeDrawerWidth,
}: SideBarProps) {

  const [scrollTop, setScrollTop] = React.useState<number>(0);

  const handleOnScroll = React.useCallback((scrollTop: number) => {
    setScrollTop(scrollTop);
  }, []);

  return (
    <OutlineDrawer
      onResizeWidth={onResizeDrawerWidth}
      width={drawerWidth}
      open={drawerOpened}
      variant={UIVariant.App}
      onClose={() => toggleOpenDrawer(false)}
      header={<Workspaces/>}
      onScroll={handleOnScroll}
    >
      <div
        className={'flex w-full gap-1 flex-1 flex-col'}
      >
        <div
          style={{
            borderColor: scrollTop > 10 ? 'var(--line-divider)' : undefined,
          }}
          className={'flex border-b border-transparent bg-bg-base z-[1] pb-4 flex-col gap-1 justify-around items-center sticky top-12'}
        >
          <Favorite/>
          <NewPage/>
        </div>
        <Outline
          width={drawerWidth}
        />

        <SideBarBottom/>
      </div>
    </OutlineDrawer>
  );
}

export default SideBar;