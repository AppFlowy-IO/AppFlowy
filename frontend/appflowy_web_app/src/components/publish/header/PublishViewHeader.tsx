import { PublishViewInfo } from '@/application/collab.type';
import { usePublishContext } from '@/application/publish';
import { View } from '@/application/types';
import BreadcrumbSkeleton from '@/components/_shared/skeleton/BreadcrumbSkeleton';
import { findAncestors, findView } from '@/components/publish/header/utils';
import { createHotkey, HOT_KEY_NAME } from '@/utils/hotkeys';
import { openOrDownload } from '@/utils/open_schema';
import { getPlatform } from '@/utils/platform';
import { Divider, IconButton, Tooltip } from '@mui/material';
import { debounce } from 'lodash-es';
import React, { useCallback, useEffect, useMemo } from 'react';
import { OutlinePopover } from '@/components/publish/outline';
import { useTranslation } from 'react-i18next';
import Breadcrumb from './Breadcrumb';
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
  const crumbs = useMemo(() => {
    if (!viewMeta || !outline) return [];
    const ancestors = findAncestors(outline.children, viewMeta?.view_id);

    if (ancestors) return ancestors;
    if (!viewMeta?.ancestor_views) return [];
    const parseToView = (ancestor: PublishViewInfo): View => {
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

  const [openPopover, setOpenPopover] = React.useState(false);
  const isMobile = useMemo(() => {
    return getPlatform().isMobile;
  }, []);

  const debounceClosePopover = useMemo(() => {
    return debounce(() => {
      setOpenPopover(false);
    }, 200);
  }, []);

  const onKeyDown = useCallback((e: KeyboardEvent) => {
    switch (true) {
      case createHotkey(HOT_KEY_NAME.TOGGLE_SIDEBAR)(e):
        e.preventDefault();
        if (openDrawer) {
          onCloseDrawer();
        } else {
          onOpenDrawer();
        }

        break;
      default:
        break;
    }
  }, [onCloseDrawer, onOpenDrawer, openDrawer]);

  useEffect(() => {
    window.addEventListener('keydown', onKeyDown);
    return () => {
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [onKeyDown]);

  const handleOpenPopover = useCallback(() => {
    debounceClosePopover.cancel();
    if (openDrawer) {
      return;
    }

    setOpenPopover(true);
  }, [openDrawer, debounceClosePopover]);

  const debounceOpenPopover = useMemo(() => {
    debounceClosePopover.cancel();
    return debounce(handleOpenPopover, 100);
  }, [handleOpenPopover, debounceClosePopover]);

  return (
    <div
      style={{
        backdropFilter: 'saturate(180%) blur(16px)',
        background: 'var(--bg-header)',
        height: HEADER_HEIGHT,
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
          >
            <IconButton
              {...{
                onMouseEnter: debounceOpenPopover,
                onMouseLeave: debounceClosePopover,
                onClick: () => {
                  setOpenPopover(false);
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
