import MobileOutlineWithCover from '@/components/_shared/mobile-outline/MobileOutlineWithCover';
import { useAppFavorites, useAppHandlers } from '@/components/app/app.hooks';
import { orderBy } from 'lodash-es';
import React, { useEffect, useMemo } from 'react';
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
  const sortedViews = useMemo(() => {
    return orderBy(favoriteViews, ['favorited_at'], ['desc']);
  }, [favoriteViews]);

  return (
    <div className={'flex flex-col gap-5 py-2'}>
      {sortedViews?.map((view) => (
        <MobileOutlineWithCover
          timePrefix={t('sideBar.favoriteAt') + ' '}
          key={view.view_id}
          time={view.favorited_at}
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