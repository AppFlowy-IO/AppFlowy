import { UIVariant } from '@/application/types';
import { Breadcrumb } from '@/components/_shared/breadcrumb';
import { useOutlinePopover } from '@/components/_shared/outline/outline.hooks';
import BreadcrumbSkeleton from '@/components/_shared/skeleton/BreadcrumbSkeleton';
import { AppContext, useAppHandlers, useBreadcrumb } from '@/components/app/app.hooks';
import { IconButton } from '@mui/material';
import { ReactComponent as SideOutlined } from '@/assets/side_outlined.svg';

import React, { memo, lazy, Suspense, useContext, useMemo } from 'react';
import Recent from 'src/components/app/recent/Recent';

import OutlinePopover from '@/components/_shared/outline/OutlinePopover';

const RightMenu = lazy(() => import('@/components/app/header/RightMenu'));

interface AppHeaderProps {
  onOpenDrawer: () => void;
  drawerWidth: number;
  openDrawer: boolean;
  onCloseDrawer: () => void;
}

const HEADER_HEIGHT = 48;

export function AppHeader ({
  onOpenDrawer, openDrawer, onCloseDrawer,
}: AppHeaderProps) {
  const {
    openPopover, debounceClosePopover, handleOpenPopover, debounceOpenPopover, handleClosePopover,
  } = useOutlinePopover({
    onOpenDrawer, openDrawer, onCloseDrawer,
  });

  const isTrash = window.location.pathname === '/app/trash';

  const crumbs = useBreadcrumb();

  const displayMenuButton = !openDrawer && window.innerWidth >= 480;

  const toView = useAppHandlers().toView;
  const rendered = useContext(AppContext)?.rendered;

  const recent = useMemo(() => <Recent />, []);

  return (
    <div
      style={{
        backdropFilter: 'saturate(180%) blur(16px)',
        background: 'var(--bg-header)',
        height: HEADER_HEIGHT,
        minHeight: HEADER_HEIGHT,
      }}
      className={'appflowy-top-bar transform-gpu sticky top-0 z-10 flex px-5'}
    >
      <div className={'flex w-full items-center justify-between gap-4 overflow-hidden'}>
        {displayMenuButton && (
          <OutlinePopover
            {...{
              onMouseEnter: handleOpenPopover,
              onMouseLeave: debounceClosePopover,
            }}
            open={openPopover}
            onClose={debounceClosePopover}
            content={recent}
          >
            <IconButton
              {...{
                onMouseEnter: debounceOpenPopover,
                onMouseLeave: debounceClosePopover,
                onClick: () => {
                  handleClosePopover();
                  onOpenDrawer();
                },
              }}

            >
              <SideOutlined className={'h-4 w-4 text-text-caption'} />
            </IconButton>
          </OutlinePopover>

        )}
        <div className={'h-full flex-1 overflow-hidden'}>
          {isTrash || crumbs && crumbs.length === 0 ? null :
            !crumbs ? <div className={'h-[48px] flex items-center'}><BreadcrumbSkeleton /></div> :
              <Breadcrumb
                toView={toView}
                variant={UIVariant.App}
                crumbs={crumbs}
              />}
        </div>
        {rendered && <Suspense fallback={null}>
          <RightMenu />
        </Suspense>}

      </div>
    </div>
  );
}

export default memo(AppHeader);