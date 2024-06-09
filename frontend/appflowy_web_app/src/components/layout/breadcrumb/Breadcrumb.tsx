import { useCrumbs } from '@/application/folder-yjs';
import Item from '@/components/layout/breadcrumb/Item';
import React, { useMemo } from 'react';

export function Breadcrumb() {
  const crumbs = useCrumbs();

  const renderCrumb = useMemo(() => {
    return crumbs?.map((crumb, index) => {
      const isLast = index === crumbs.length - 1;
      const key = crumb.rowId ? `${crumb.viewId}-${crumb.rowId}` : `${crumb.viewId}`;

      return (
        <React.Fragment key={key}>
          <Item crumb={crumb} disableClick={isLast} />
          {!isLast && <span>/</span>}
        </React.Fragment>
      );
    });
  }, [crumbs]);

  return <div className={'flex flex-1 items-center gap-2 overflow-hidden'}>{renderCrumb}</div>;
}

export default Breadcrumb;
