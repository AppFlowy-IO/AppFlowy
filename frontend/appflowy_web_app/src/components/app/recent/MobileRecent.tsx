import MobileOutlineWithCover from '@/components/_shared/mobile-outline/MobileOutlineWithCover';
import { useAppHandlers } from '@/components/app/app.hooks';
import { useRecent } from '@/components/app/recent/useRecent';
import React from 'react';
import { useTranslation } from 'react-i18next';

function MobileRecent ({
  onClose,
}: {
  onClose: () => void;
}) {
  const {
    views,
  } = useRecent();

  const navigateToView = useAppHandlers().toView;
  const { t } = useTranslation();

  return (
    <div className={'flex flex-col gap-5 py-2'}>
      {views?.map((view) => (
        <MobileOutlineWithCover
          key={view.view_id}
          timePrefix={t('sideBar.lastViewed') + ' '}

          view={view}
          navigateToView={async (viewId: string) => {
            await navigateToView(viewId);
            onClose();
          }}
        />
      ))}
    </div>
  );
}

export default MobileRecent;