import { usePublishContext } from '@/application/publish';
import { AFScroller } from '@/components/_shared/scroller';
import React from 'react';
import { ReactComponent as AppFlowyLogo } from '@/assets/appflowy.svg';
import { useNavigate } from 'react-router-dom';
import MobileOutline from 'src/components/_shared/mobile-outline/MobileOutline';

function PublishMobileFolder ({
  onClose,
}: {
  onClose: () => void;
}) {
  const outline = usePublishContext()?.outline;
  const viewId = usePublishContext()?.viewMeta?.view_id;
  const navigateToView = usePublishContext()?.toView;
  const navigate = useNavigate();

  return (
    <AFScroller
      overflowXHidden
      className={'flex w-full flex-1 flex-col px-4'}
    >
      <div
        onClick={() => {
          navigate('/');
        }}
        className={'sticky top-0 w-full bg-bg-body z-[10] py-2 pb-0'}
      >
        <AppFlowyLogo className={'w-[100px] h-[48px]'} />
      </div>
      {outline && <MobileOutline
        outline={outline}
        onClose={onClose}
        selectedViewId={viewId}
        navigateToView={navigateToView}
      />}
    </AFScroller>

  );
}

export default PublishMobileFolder;