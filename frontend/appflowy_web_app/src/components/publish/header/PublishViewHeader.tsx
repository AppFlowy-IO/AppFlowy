import { usePublishContext } from '@/application/publish';
import { useCurrentUser } from '@/components/app/app.hooks';
import { openOrDownload } from '@/components/publish/header/utils';
import { createHotkey, HOT_KEY_NAME } from '@/utils/hotkeys';
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
  const crumbs = useMemo(() => {
    const ancestors = viewMeta?.ancestor_views.slice(1) || [];

    return ancestors.map((ancestor) => {
      let icon;

      try {
        const extra = ancestor?.extra ? JSON.parse(ancestor.extra) : {};

        icon = extra.icon?.value || ancestor.icon?.value;
      } catch (e) {
        // ignore
      }

      return {
        viewId: ancestor.view_id,
        name: ancestor.name,
        icon: icon,
        layout: ancestor.layout,
        extra: ancestor.extra,
      };
    });
  }, [viewMeta]);
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

  const currentUser = useCurrentUser();

  const isAppFlowyUser = currentUser?.email?.endsWith('@appflowy.io');

  return (
    <div
      style={{
        backdropFilter: 'saturate(180%) blur(16px)',
        background: 'var(--header)',
        height: HEADER_HEIGHT,
      }}
      className={'appflowy-top-bar sticky top-0 z-10 flex px-5'}
    >
      <div className={'flex w-full items-center justify-between gap-4 overflow-hidden'}>
        {!openDrawer && (
          <OutlinePopover
            {...isMobile ? undefined : {
              onMouseEnter: handleOpenPopover,
              onMouseLeave: debounceClosePopover,
            }}
            open={openPopover}
            onClose={debounceClosePopover}
            drawerWidth={drawerWidth}
          >
            <IconButton
              {...isMobile ? {
                onTouchEnd: () => {
                  setOpenPopover(prev => !prev);
                },
              } : {
                onMouseEnter: debounceOpenPopover,
                onMouseLeave: debounceClosePopover,
                onClick: () => {
                  setOpenPopover(false);
                  onOpenDrawer();
                },
              }}

            >
              <SideOutlined className={'h-4 w-4'} />
            </IconButton>
          </OutlinePopover>
        )}

        <div className={'h-full flex-1 overflow-hidden'}>
          <Breadcrumb crumbs={crumbs} />
        </div>

        <div className={'flex items-center gap-2'}>

          <MoreActions />
          {isAppFlowyUser && <Duplicate />}
          <Divider
            orientation={'vertical'}
            className={'mx-2'}
            flexItem
          />
          <Tooltip title={t('publish.downloadApp')}>
            <button onClick={openOrDownload}>
              <Logo className={'h-6 w-6'} />
            </button>
          </Tooltip>
        </div>
      </div>
    </div>
  );
}

export default PublishViewHeader;
