import BreadcrumbItem, { Crumb } from '@/components/publish/header/BreadcrumbItem';
import React, { useMemo } from 'react';
import { ReactComponent as RightIcon } from '@/assets/arrow_right.svg';

export function Breadcrumb({ crumbs }: { crumbs: Crumb[] }) {
  const renderCrumb = useMemo(() => {
    return crumbs?.map((crumb, index) => {
      const isLast = index === crumbs.length - 1;
      const key = crumb.rowId ? `${crumb.viewId}-${crumb.rowId}` : `${crumb.viewId}`;

      return (
        <div className={`${isLast ? 'text-text-title' : 'text-text-caption'} flex items-center gap-2`} key={key}>
          <BreadcrumbItem crumb={crumb} disableClick={isLast} />
          {!isLast && <RightIcon className={'h-4 w-4'} />}
        </div>
      );
    });
  }, [crumbs]);

  return <div className={'flex flex-1 items-center gap-2 overflow-hidden'}>{renderCrumb}</div>;
}

export default Breadcrumb;
