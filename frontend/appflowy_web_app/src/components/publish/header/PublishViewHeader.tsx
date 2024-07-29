import { usePublishContext } from '@/application/publish';
import { openOrDownload } from '@/components/publish/header/utils';
import { Divider, IconButton, Tooltip } from '@mui/material';
import { debounce } from 'lodash-es';
import React, { Suspense, useCallback, useMemo } from 'react';
import { OutlinePopover } from '@/components/publish/outline';
import { useTranslation } from 'react-i18next';
import Breadcrumb from './Breadcrumb';
import { ReactComponent as Logo } from '@/assets/logo.svg';
import MoreActions from './MoreActions';
import { ReactComponent as SideOutlined } from '@/assets/side_outlined.svg';
import { Duplicate } from './duplicate';

export const HEADER_HEIGHT = 48;

export function PublishViewHeader({ onOpenDrawer, openDrawer }: { onOpenDrawer: () => void; openDrawer: boolean }) {
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

  const debounceClosePopover = useMemo(() => {
    return debounce(() => {
      setOpenPopover(false);
    }, 200);
  }, []);

  const handleOpenPopover = useCallback(() => {
    debounceClosePopover.cancel();
    if (openDrawer) {
      return;
    }

    setOpenPopover(true);
  }, [openDrawer, debounceClosePopover]);

  return (
    <div
      style={{
        backdropFilter: 'saturate(180%) blur(16px)',
        background: 'var(--header)',
        height: HEADER_HEIGHT,
      }}
      className={'appflowy-top-bar sticky top-0 z-10 flex px-5'}
    >
      <div className={'flex w-full items-center justify-between gap-2 overflow-hidden'}>
        <Suspense fallback={null}>
          {!openDrawer && openPopover && (
            <OutlinePopover
              onMouseEnter={handleOpenPopover}
              onMouseLeave={debounceClosePopover}
              open={openPopover}
              onClose={debounceClosePopover}
            >
              <IconButton
                className={'hidden'}
                onClick={() => {
                  setOpenPopover(false);
                  onOpenDrawer();
                }}
                onMouseEnter={handleOpenPopover}
                onMouseLeave={debounceClosePopover}
              >
                <SideOutlined className={'h-4 w-4'} />
              </IconButton>
            </OutlinePopover>
          )}
        </Suspense>

        <div className={'h-full flex-1 overflow-hidden'}>
          <Breadcrumb crumbs={crumbs} />
        </div>

        <div className={'flex items-center gap-2'}>
          <MoreActions />
          <Suspense fallback={null}>
            <Duplicate />
          </Suspense>
          <Divider orientation={'vertical'} className={'mx-2'} flexItem />
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
