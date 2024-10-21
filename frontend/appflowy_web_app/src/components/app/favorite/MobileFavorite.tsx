import MobileOutlineWithCover from '@/components/_shared/mobile-outline/MobileOutlineWithCover';
import { useAppFavorites, useAppHandlers } from '@/components/app/app.hooks';
import React, { useEffect } from 'react';
import { useTranslation } from 'react-i18next';

function MobileFavorite ({
  onClose,
}: {
  onClose: () => void;
}) {
  const {
    favoriteViews,
    loadFavoriteViews,
  } = useAppFavorites();

  useEffect(() => {
    void loadFavoriteViews?.();
  }, [loadFavoriteViews]);

  const navigateToView = useAppHandlers().toView;
  const { t } = useTranslation();

  return (
    <div className={'flex flex-col gap-5 py-2'}>
      {favoriteViews?.map((view) => (
        <MobileOutlineWithCover
          timePrefix={t('sideBar.favoriteAt') + ' '}
          key={view.view_id}
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

export default MobileFavorite;