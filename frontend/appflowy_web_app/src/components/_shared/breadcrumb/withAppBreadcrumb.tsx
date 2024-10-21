import { UIVariant } from '@/application/types';
import { BreadcrumbProps } from '@/components/_shared/breadcrumb/Breadcrumb';
import BreadcrumbSkeleton from '@/components/_shared/skeleton/BreadcrumbSkeleton';
import { useAppHandlers, useBreadcrumb } from '@/components/app/app.hooks';
import React from 'react';

export function withAppBreadcrumb (Component: React.ComponentType<BreadcrumbProps>) {
  return function PublishBreadcrumbComponent () {
    const isTrash = window.location.pathname === '/app/trash';

    const crumbs = useBreadcrumb();
    const toView = useAppHandlers().toView;

    return (
      <div className={'h-full flex-1 overflow-hidden'}>
        {!crumbs ? <BreadcrumbSkeleton /> :
          !isTrash && <Component
            toView={toView}
            variant={UIVariant.App}
            crumbs={crumbs}
          />
        }
      </div>
    );
  };
}