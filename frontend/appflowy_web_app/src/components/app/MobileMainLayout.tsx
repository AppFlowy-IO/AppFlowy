import { UIVariant } from '@/application/types';
import MobileTopBar from '@/components/_shared/mobile-topbar/MobileTopBar';
import { AFScroller } from '@/components/_shared/scroller';
import { useViewErrorStatus } from '@/components/app/app.hooks';
import Main from '@/components/app/Main';
import DeletedPageComponent from '@/components/error/PageHasBeenDeleted';
import RecordNotFound from '@/components/error/RecordNotFound';
import SomethingError from '@/components/error/SomethingError';
import React, { useMemo } from 'react';
import { ErrorBoundary } from 'react-error-boundary';

function MobileMainLayout () {
  const { notFound, deleted } = useViewErrorStatus();

  const main = useMemo(() => {
    if (deleted) {
      return <DeletedPageComponent />;
    }

    return notFound ? <RecordNotFound isViewNotFound /> : <Main />;
  }, [deleted, notFound]);

  return (
    <div className={'h-screen w-screen'}>
      <AFScroller
        overflowXHidden
        overflowYHidden={false}
        className={'appflowy-layout appflowy-mobile-layout flex flex-col appflowy-scroll-container h-full'}
      >
        <MobileTopBar variant={UIVariant.App} />

        <ErrorBoundary FallbackComponent={SomethingError}>
          {main}
        </ErrorBoundary>

      </AFScroller>

    </div>
  );
}

export default MobileMainLayout;