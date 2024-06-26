import { usePublishContext } from '@/application/publish';
import { openOrDownload } from '@/components/publish/header/utils';
import React, { useMemo } from 'react';
import Breadcrumb from './Breadcrumb';
import { ReactComponent as Logo } from '@/assets/logo.svg';

export function PublishViewHeader() {
  const viewMeta = usePublishContext()?.viewMeta;
  const crumbs = useMemo(() => {
    const ancestors = viewMeta?.ancestor_views || [];
    let icon = viewMeta?.icon;

    try {
      const extra = viewMeta?.extra ? JSON.parse(viewMeta.extra) : {};

      icon = extra.icon || icon;
    } catch (e) {
      // ignore
    }

    return ancestors.map((ancestor) => ({
      viewId: ancestor.view_id,
      name: ancestor.name,
      icon: icon || String(viewMeta?.layout),
    }));
  }, [viewMeta]);

  return (
    <div className={'appflowy-top-bar flex h-[64px] px-5'}>
      <div className={'flex w-full items-center justify-between overflow-hidden'}>
        <Breadcrumb crumbs={crumbs} />
        <button onClick={openOrDownload}>
          <Logo className={'h-6 w-6'} />
        </button>
      </div>
    </div>
  );
}

export default PublishViewHeader;
