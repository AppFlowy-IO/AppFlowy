import { View } from '@/application/types';
import { AFScroller } from '@/components/_shared/scroller';
import BreadcrumbItem from '@/components/publish/header/BreadcrumbItem';
import React, { useMemo } from 'react';
import { ReactComponent as RightIcon } from '@/assets/arrow_right.svg';

export function Breadcrumb ({ crumbs }: { crumbs: View[] }) {
  const renderCrumb = useMemo(() => {
    return crumbs?.map((crumb, index) => {
      const isLast = index === crumbs.length - 1;
      const key = `${crumb.view_id}-${index}`;

      return (
        <div className={`${isLast ? 'text-text-title' : 'text-text-caption'} flex items-center gap-2`} key={key}>
          <BreadcrumbItem crumb={crumb} disableClick={isLast} />
          {!isLast && <RightIcon className={'h-4 w-4'} />}
        </div>
      );
    });
  }, [crumbs]);

  return (
    <div className={'relative h-full w-full flex-1  overflow-hidden'}>
      <AFScroller overflowYHidden className={'flex w-full items-center gap-2'}>
        {renderCrumb}{' '}
      </AFScroller>
    </div>
  );
}

export default Breadcrumb;
