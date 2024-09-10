import { Breadcrumb } from '@/components/_shared/breadcrumb';
import { OutlinePopover } from '@/components/_shared/outline';
import Outline from '@/components/_shared/outline/Outline';
import { useOutlinePopover } from '@/components/_shared/outline/outline.hooks';
import BreadcrumbSkeleton from '@/components/_shared/skeleton/BreadcrumbSkeleton';
import { AppContext, useAppOutline, useAppViewId } from '@/components/app/app.hooks';
import { findAncestors } from '@/components/publish/header/utils';
import { Button, IconButton } from '@mui/material';
import { ReactComponent as SideOutlined } from '@/assets/side_outlined.svg';

import React, { memo, useContext, useMemo } from 'react';
import { useTranslation } from 'react-i18next';

interface AppHeaderProps {
  onOpenDrawer: () => void;
  drawerWidth: number;
  openDrawer: boolean;
  onCloseDrawer: () => void;
}

const HEADER_HEIGHT = 48;

export function AppHeader ({
  onOpenDrawer, drawerWidth, openDrawer, onCloseDrawer,
}: AppHeaderProps) {
  const {
    openPopover, debounceClosePopover, handleOpenPopover, debounceOpenPopover, handleClosePopover,
  } = useOutlinePopover({
    onOpenDrawer, openDrawer, onCloseDrawer,
  });
  const { t } = useTranslation();
  const outline = useAppOutline();
  const viewId = useAppViewId();
  const crumbs = useMemo(() => {
    if (!outline || !viewId) return [];

    return findAncestors(outline.children, viewId) || [];
  }, [viewId, outline]);
  const navigateToView = useContext(AppContext)?.toView;

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
        {!openDrawer && (
          <OutlinePopover
            {...{
              onMouseEnter: handleOpenPopover,
              onMouseLeave: debounceClosePopover,
            }}
            open={openPopover}
            onClose={debounceClosePopover}
            drawerWidth={drawerWidth}
            content={<Outline navigateToView={navigateToView} selectedViewId={viewId} outline={outline}
                              width={drawerWidth}
            />}
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
          {!crumbs.length ? <div className={'h-[48px] flex items-center'}><BreadcrumbSkeleton /></div> : <Breadcrumb
            toView={undefined}
            crumbs={crumbs}
          />}
        </div>
        <div className={'flex items-center gap-2'}>
          <Button size={'small'} variant={'contained'} color={'primary'}>{t('shareAction.buttonText')}</Button>
        </div>
      </div>
    </div>
  );
}

export default memo(AppHeader);