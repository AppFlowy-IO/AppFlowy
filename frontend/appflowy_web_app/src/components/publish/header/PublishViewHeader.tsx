import { usePublishContext } from '@/application/publish';
import React, { useMemo } from 'react';
import Breadcrumb from './Breadcrumb';

export function PublishViewHeader() {
  const viewMeta = usePublishContext()?.viewMeta;
  const crumbs = useMemo(() => {
    const ancestors = viewMeta?.ancestor_views || [];

    return ancestors.map((ancestor) => ({
      viewId: ancestor.view_id,
      name: ancestor.name,
      icon: ancestor.icon || String(viewMeta?.layout),
    }));
  }, [viewMeta]);

  return (
    <div className={'appflowy-top-bar flex h-[64px] p-4'}>
      <div className={'flex w-full items-center justify-between overflow-hidden'}>
        <Breadcrumb crumbs={crumbs} />
      </div>
    </div>
  );
}

export default PublishViewHeader;
