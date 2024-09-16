import { Breadcrumb } from '@/components/_shared/breadcrumb';
import MoreActions from '@/components/_shared/more-actions/MoreActions';
import { OutlinePopover } from '@/components/_shared/outline';
import { useOutlinePopover } from '@/components/_shared/outline/outline.hooks';
import { findAncestors } from '@/components/_shared/outline/utils';
import BreadcrumbSkeleton from '@/components/_shared/skeleton/BreadcrumbSkeleton';
import { useAppHandlers, useAppOutline, useAppViewId } from '@/components/app/app.hooks';
import { IconButton } from '@mui/material';
import { ReactComponent as SideOutlined } from '@/assets/side_outlined.svg';

import React, { memo, useMemo } from 'react';
import Recent from 'src/components/app/recent/Recent';
import ShareButton from 'src/components/app/share/ShareButton';

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

  const outline = useAppOutline();
  const viewId = useAppViewId();
  const isTrash = window.location.pathname === '/app/trash';

  const crumbs = useMemo(() => {
    if (!outline || !viewId) return [];

    return findAncestors(outline, viewId) || [];
  }, [outline, viewId]);

  const displayMenuButton = !openDrawer && window.innerWidth >= 480;

  const toView = useAppHandlers().toView;

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
          {isTrash ? null :
            !crumbs.length ? <div className={'h-[48px] flex items-center'}><BreadcrumbSkeleton /></div> :
              <Breadcrumb
                toView={toView}
                variant={'app'}
                crumbs={crumbs}
              />}
        </div>
        <div className={'flex items-center gap-2'}>
          <MoreActions />
          <ShareButton />
        </div>
      </div>
    </div>
  );
}

export default memo(AppHeader);