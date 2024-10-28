import { UIVariant, YDoc } from '@/application/types';
import { AFScroller } from '@/components/_shared/scroller';
import PublishMain from '@/components/publish/PublishMain';
import React, { Suspense } from 'react';

const MobileTopBar = React.lazy(() => import('@/components/_shared/mobile-topbar/MobileTopBar'));

function PublishMobileLayout ({
  doc,
}: {
  doc?: YDoc;
}) {
  return (
    <div
      className={'h-screen w-screen'}
    >
      <AFScroller
        overflowXHidden
        className={'appflowy-layout appflowy-mobile-layout appflowy-scroll-container h-full'}
      >
        <Suspense
          fallback={
            <div className={'flex items-center justify-between w-full h-[48px] min-h-[48px] px-4 gap-2'} />}
        >
          <MobileTopBar variant={UIVariant.Publish} />
        </Suspense>
        <PublishMain
          doc={doc}
          isTemplate={false}
        />
      </AFScroller>
    </div>
  );
}

export default PublishMobileLayout;