import { usePublishContext } from '@/application/publish';
import { openOrDownload } from '@/components/publish/header/utils';
import { Divider, IconButton } from '@mui/material';
import { debounce } from 'lodash-es';
import React, { useCallback, useMemo } from 'react';
import OutlinePopover from '@/components/publish/outline/OutlinePopover';
import Breadcrumb from './Breadcrumb';
import { ReactComponent as Logo } from '@/assets/logo.svg';
import MoreActions from './MoreActions';
import { ReactComponent as SideOutlined } from '@/assets/side_outlined.svg';

export function PublishViewHeader({
  onOpenDrawer,
  drawerWidth,
  openDrawer,
}: {
  onOpenDrawer: () => void;
  openDrawer: boolean;
  drawerWidth: number;
}) {
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
        transform: openDrawer ? `translateX(${drawerWidth}px)` : 'none',
        width: openDrawer ? `calc(100% - ${drawerWidth}px)` : '100%',
        transition: 'width 0.2s ease-in-out, transform 0.2s ease-in-out',
      }}
      className={'appflowy-top-bar flex h-[48px] px-5'}
    >
      <div className={'flex w-full items-center justify-between gap-2 overflow-hidden'}>
        {!openDrawer && (
          <OutlinePopover
            onMouseEnter={handleOpenPopover}
            onMouseLeave={debounceClosePopover}
            open={openPopover}
            onClose={debounceClosePopover}
          >
            <IconButton
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

        <div className={'flex-1 overflow-hidden'}>
          <Breadcrumb crumbs={crumbs} />
        </div>

        <div className={'flex items-center gap-2'}>
          <MoreActions />
          <Divider orientation={'vertical'} className={'mx-2'} flexItem />
          <button onClick={openOrDownload}>
            <Logo className={'h-6 w-6'} />
          </button>
        </div>
      </div>
    </div>
  );
}

export default PublishViewHeader;
