import { UIVariant, View } from '@/application/types';
import { AFScroller } from '@/components/_shared/scroller';
import BreadcrumbItem from '@/components/_shared/breadcrumb/BreadcrumbItem';
import React, { memo, useMemo } from 'react';
import { ReactComponent as RightIcon } from '@/assets/arrow_right.svg';

export function Breadcrumb ({ crumbs, toView, variant }: {
  crumbs: View[];
  toView?: (viewId: string) => Promise<void>;
  variant?: UIVariant;
}) {
  const renderCrumb = useMemo(() => {

    return crumbs?.map((crumb, index) => {
      const isLast = index === crumbs.length - 1;
      const key = `${crumb.view_id}-${index}`;

      return (
        <div className={`${isLast ? 'text-text-title' : 'text-text-caption'} flex items-center gap-2`} key={key}>
          <BreadcrumbItem variant={variant} toView={toView} crumb={crumb} disableClick={isLast} />
          {!isLast && <RightIcon className={'h-4 w-4'} />}
        </div>
      );
    });
  }, [crumbs, toView, variant]);

  return (
    <div className={'relative h-full w-full flex-1  overflow-hidden'}>
      <AFScroller overflowYHidden className={'flex w-full items-center gap-2'}>
        {renderCrumb}{' '}
      </AFScroller>
    </div>
  );
}

export default memo(Breadcrumb);
