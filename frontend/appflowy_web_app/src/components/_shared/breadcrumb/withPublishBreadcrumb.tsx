import { usePublishContext } from '@/application/publish';
import { UIVariant } from '@/application/types';
import { BreadcrumbProps } from '@/components/_shared/breadcrumb/Breadcrumb';
import BreadcrumbSkeleton from '@/components/_shared/skeleton/BreadcrumbSkeleton';
import React from 'react';

export function withPublishBreadcrumb (Component: React.ComponentType<BreadcrumbProps>) {
  return function PublishBreadcrumbComponent () {
    const toView = usePublishContext()?.toView;
    const crumbs = usePublishContext()?.breadcrumbs;

    return (
      <div className={'h-full flex-1 overflow-hidden'}>
        {!crumbs ? <BreadcrumbSkeleton /> :
          <Component
            toView={toView}
            variant={UIVariant.Publish}
            crumbs={crumbs}
          />
        }
      </div>
    );
  };
}