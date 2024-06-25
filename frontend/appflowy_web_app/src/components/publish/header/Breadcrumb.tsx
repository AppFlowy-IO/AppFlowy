import BreadcrumbItem, { Crumb } from 'src/components/publish/header/BreadcrumbItem';
import React, { useMemo } from 'react';
import { ReactComponent as RightIcon } from '$icons/16x/right.svg';

export function Breadcrumb({ crumbs }: { crumbs: Crumb[] }) {
  const renderCrumb = useMemo(() => {
    return crumbs?.map((crumb, index) => {
      const isLast = index === crumbs.length - 1;
      const key = crumb.rowId ? `${crumb.viewId}-${crumb.rowId}` : `${crumb.viewId}`;

      return (
        <React.Fragment key={key}>
          <BreadcrumbItem crumb={crumb} disableClick={isLast} />
          {!isLast && <RightIcon className={'h-4 w-4'} />}
        </React.Fragment>
      );
    });
  }, [crumbs]);

  return <div className={'flex flex-1 items-center gap-2 overflow-hidden'}>{renderCrumb}</div>;
}

export default Breadcrumb;
