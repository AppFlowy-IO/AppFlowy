import { ViewInfo, View } from '@/application/types';
import { usePublishContext } from '@/application/publish';
import { useOutlinePopover } from '@/components/_shared/outline/outline.hooks';
import BreadcrumbSkeleton from '@/components/_shared/skeleton/BreadcrumbSkeleton';
import { findAncestors, findView } from '@/components/publish/header/utils';
import { openOrDownload } from '@/utils/open_schema';
import { getPlatform } from '@/utils/platform';
import { Divider, IconButton, Tooltip } from '@mui/material';
import React, { useMemo } from 'react';
import Outline from '@/components/_shared/outline/Outline';
import { OutlinePopover } from '@/components/_shared/outline';
import { useTranslation } from 'react-i18next';
import { Breadcrumb } from '@/components/_shared/breadcrumb';
import { ReactComponent as Logo } from '@/assets/logo.svg';
import MoreActions from './MoreActions';
import { ReactComponent as SideOutlined } from '@/assets/side_outlined.svg';
import { Duplicate } from './duplicate';

export const HEADER_HEIGHT = 48;

export function PublishViewHeader ({
  drawerWidth, onOpenDrawer, openDrawer, onCloseDrawer,
}: {
  onOpenDrawer: () => void;
  drawerWidth: number;
  openDrawer: boolean;
  onCloseDrawer: () => void
}) {
  const { t } = useTranslation();
  const viewMeta = usePublishContext()?.viewMeta;
  const outline = usePublishContext()?.outline;
  const toView = usePublishContext()?.toView;
  const crumbs = useMemo(() => {
    if (!viewMeta || !outline) return [];
    const ancestors = findAncestors(outline.children, viewMeta?.view_id);

    if (ancestors) return ancestors;
    if (!viewMeta?.ancestor_views) return [];
    const parseToView = (ancestor: ViewInfo): View => {
      let extra = null;

      try {
        extra = ancestor.extra ? JSON.parse(ancestor.extra) : null;
      } catch (e) {
        // do nothing
      }

      return {
        view_id: ancestor.view_id,
        name: ancestor.name,
        icon: ancestor.icon,
        layout: ancestor.layout,
        extra,
        is_published: true,
        children: [],
      };
    };

    const currentView = parseToView(viewMeta);

    return viewMeta?.ancestor_views.slice(1).map(item => findView(outline.children, item.view_id) || parseToView(item)) || [currentView];
  }, [viewMeta, outline]);

  const {
    openPopover, debounceClosePopover, handleOpenPopover, debounceOpenPopover, handleClosePopover,
  } = useOutlinePopover({
    onOpenDrawer, openDrawer, onCloseDrawer,
  });
  const isMobile = useMemo(() => {
    return getPlatform().isMobile;
  }, []);
  const viewId = viewMeta?.view_id;

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
        {!openDrawer && !isMobile && (
          <OutlinePopover
            {...{
              onMouseEnter: handleOpenPopover,
              onMouseLeave: debounceClosePopover,
            }}
            open={openPopover}
            onClose={debounceClosePopover}
            drawerWidth={drawerWidth}
            content={<Outline selectedViewId={viewId} navigateToView={toView} outline={outline} width={drawerWidth} />}
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
          {!viewMeta ? <div className={'h-[48px] flex items-center'}><BreadcrumbSkeleton /></div> : <Breadcrumb
            toView={toView}
            crumbs={crumbs}
          />}
        </div>

        <div className={'flex items-center gap-2'}>
          <MoreActions />
          <Duplicate />
          <Divider
            orientation={'vertical'}
            className={'mx-2'}
            flexItem
          />
          <Tooltip title={t('publish.downloadApp')}>
            <button onClick={() => openOrDownload()}>
              <Logo className={'h-6 w-6'} />
            </button>
          </Tooltip>
        </div>
      </div>
    </div>
  );
}

export default PublishViewHeader;
