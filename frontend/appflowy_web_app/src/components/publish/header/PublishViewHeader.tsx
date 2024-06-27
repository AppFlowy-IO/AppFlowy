import { usePublishContext } from '@/application/publish';
import { openOrDownload } from '@/components/publish/header/utils';
import { Divider } from '@mui/material';
import React, { useMemo } from 'react';
import Breadcrumb from './Breadcrumb';
import { ReactComponent as Logo } from '@/assets/logo.svg';
import MoreActions from './MoreActions';

export function PublishViewHeader() {
  const viewMeta = usePublishContext()?.viewMeta;
  const crumbs = useMemo(() => {
    const ancestors = viewMeta?.ancestor_views || [];

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
        icon: icon || String(viewMeta?.layout),
      };
    });
  }, [viewMeta]);

  return (
    <div className={'appflowy-top-bar flex h-[64px] px-5'}>
      <div className={'flex w-full items-center justify-between gap-2 overflow-hidden'}>
        <div className={'flex-1'}>
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
