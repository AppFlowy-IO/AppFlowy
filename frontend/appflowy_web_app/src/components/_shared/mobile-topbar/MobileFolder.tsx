import MobileMore from '@/components/_shared/mobile-topbar/MobileMore';
import { AFScroller } from '@/components/_shared/scroller';
import { ViewTab, ViewTabs } from '@/components/_shared/tabs/ViewTabs';
import { AppContext, useAppOutline, useAppViewId } from '@/components/app/app.hooks';
import MobileFavorite from '@/components/app/favorite/MobileFavorite';
import MobileRecent from '@/components/app/recent/MobileRecent';
import MobileWorkspaces from '@/components/app/workspaces/MobileWorkspaces';
import React, { useContext } from 'react';
import { useTranslation } from 'react-i18next';
import MobileOutline from 'src/components/_shared/mobile-outline/MobileOutline';
import SwipeableViews from 'react-swipeable-views';

enum ViewTabsKey {
  Space,
  Recent,
  Favorite,
}

function MobileFolder ({
  onClose,
}: {
  onClose: () => void;
}) {
  const outline = useAppOutline();
  const viewId = useAppViewId();
  const navigateToView = useContext(AppContext)?.toView;
  const [selectedTab, setSelectedTab] = React.useState<ViewTabsKey>(ViewTabsKey.Space);
  const { t } = useTranslation();

  return (
    <AFScroller
      overflowXHidden
      className={'flex w-full flex-1 flex-col gap-2'}
    >
      <div className={'sticky top-0 w-full bg-bg-body z-[10] p-2 pb-0'}>
        <div className={'flex items-center mb-2 justify-between'}>
          <div className={'flex-1 p-2'}>
            <MobileWorkspaces onClose={onClose} />
          </div>
          <MobileMore onClose={onClose} />
        </div>
        <ViewTabs
          value={selectedTab}
          sx={{
            '& .MuiTabs-indicator': {
              transform: 'scaleX(0.4)',
            },
          }}
          onChange={(_, value) => setSelectedTab(value)}
        >
          <ViewTab
            value={ViewTabsKey.Space}
            label={t('sideBar.Spaces')}
          />
          <ViewTab
            value={ViewTabsKey.Recent}
            label={t('sideBar.recent')}
          />
          <ViewTab
            value={ViewTabsKey.Favorite}
            label={t('sideBar.favorites')}
          />
        </ViewTabs>
      </div>

      <SwipeableViews
        index={selectedTab}
        onChangeIndex={setSelectedTab}
        className={'h-full'}
        containerStyle={{
          height: '100%',
        }}
      >
        <div
          className={'transform-gpu pb-[60px] px-2'}
        >

          {outline && <MobileOutline
            outline={outline}
            onClose={onClose}
            selectedViewId={viewId}
            navigateToView={navigateToView}
          />}
        </div>
        <div
          className={'transform-gpu pb-[60px] px-2'}
        >
          <MobileRecent onClose={onClose} />
        </div>
        <div
          className={'transform-gpu pb-[60px] px-2'}
        >
          <MobileFavorite onClose={onClose} />
        </div>
      </SwipeableViews>

    </AFScroller>
  );
}

export default MobileFolder;