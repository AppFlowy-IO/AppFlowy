import OutlineItem from '@/components/_shared/outline/OutlineItem';
import { Popover } from '@/components/_shared/popover';
import RecentListSkeleton from '@/components/_shared/skeleton/RecentListSkeleton';
import { useAppFavorites, useAppHandlers, useAppViewId } from '@/components/app/app.hooks';
import { Collapse } from '@mui/material';
import { PopoverProps } from '@mui/material/Popover';
import dayjs from 'dayjs';
import { groupBy, sortBy } from 'lodash-es';
import React, { useEffect, useMemo } from 'react';
import { ReactComponent as FavoritedIcon } from '@/assets/favorited.svg';
import { useTranslation } from 'react-i18next';
import { ReactComponent as MoreIcon } from '@/assets/more.svg';

const popoverOrigin: Partial<PopoverProps> = {
  transformOrigin: {
    vertical: 'top',
    horizontal: 'left',
  },
  anchorOrigin: {
    vertical: 'top',
    horizontal: 'right',
  },
};

enum FavoriteGroup {
  today = 'today',
  yesterday = 'yesterday',
  thisWeek = 'thisWeek',
  Others = 'Others',
}

export function Favorite () {
  const {
    favoriteViews,
    loadFavoriteViews,
  } = useAppFavorites();
  const navigateToView = useAppHandlers().toView;
  const viewId = useAppViewId();
  const { t } = useTranslation();
  const [isExpanded, setIsExpanded] = React.useState(() => {
    return localStorage.getItem('favorite_expanded') !== 'false';
  });
  const moreButtonRef = React.useRef<HTMLDivElement>(null);
  const [moreOpened, setMoreOpened] = React.useState(false);

  useEffect(() => {
    void loadFavoriteViews?.();
  }, [loadFavoriteViews]);

  const handleToggleExpand = () => {
    setIsExpanded(!isExpanded);
    localStorage.setItem('favorite_expanded', String(!isExpanded));
  };

  const { pinViews, unpinViews } = useMemo(() => {
    return groupBy(favoriteViews, (view) => view.extra?.is_pinned ? 'pinViews' : 'unpinViews');
  }, [favoriteViews]);

  const groupByViewsWithDay = useMemo(() => {
    return groupBy(favoriteViews, (view) => {
      const date = dayjs(view.last_edited_time);
      const today = date.isSame(dayjs(), 'day');
      const yesterday = date.isSame(dayjs().subtract(1, 'day'), 'day');
      const thisWeek = date.isSame(dayjs(), 'week');

      if (today) return FavoriteGroup.today;
      if (yesterday) return FavoriteGroup.yesterday;
      if (thisWeek) return FavoriteGroup.thisWeek;
      return FavoriteGroup.Others;
    });
  }, [favoriteViews]);

  const groupByViews = useMemo(() => {
    return sortBy(Object.entries(groupByViewsWithDay), ([key]) => {
      return key === FavoriteGroup.today ? 0 : key === FavoriteGroup.yesterday ? 1 : key === FavoriteGroup.thisWeek ? 2 : 3;
    }).map(([key, value]) => {
      const timeLabel: Record<string, string> = {
        [FavoriteGroup.today]: t('calendar.navigation.today'),
        [FavoriteGroup.yesterday]: t('relativeDates.yesterday'),
        [FavoriteGroup.thisWeek]: t('sideBar.thisWeek'),
        [FavoriteGroup.Others]: t('sideBar.others'),
      };

      return <div className={'flex flex-col gap-2'} key={key}>
        <div className={'text-xs text-text-caption py-1 px-1'}>{timeLabel[key]}</div>
        <div className={'px-1'}>
          {value.map((view) =>
            <OutlineItem
              variant={'favorite'}
              key={view.view_id}
              view={view}
              navigateToView={navigateToView}
            />,
          )}
        </div>

      </div>;
    });
  }, [groupByViewsWithDay, navigateToView, t]);

  return (
    <div className={'flex w-full flex-col py-[10px] px-[10px]'}>
      <div onClick={handleToggleExpand} className={'flex h-fit my-0.5 w-full flex-col gap-2 cursor-pointer'}>
        <div
          className={
            'flex items-center w-full gap-2 rounded-[8px] py-1.5 px-0.5 text-sm hover:bg-content-blue-50 focus:bg-content-blue-50 focus:outline-none'
          }
        >
          <FavoritedIcon className={'h-5 w-5'} />
          <div className={'flex-1 truncate'}>{t('sideBar.favorites')}</div>
        </div>
      </div>
      {!favoriteViews ? <RecentListSkeleton rows={3} /> : <Collapse
        in={isExpanded}
        className={'flex px-1 transform flex-col gap-2 transition-all'}
      >
        {
          pinViews?.map((view) =>
            <OutlineItem
              variant={'favorite'}
              key={view.view_id}
              selectedViewId={viewId}
              view={view}
              navigateToView={navigateToView}
            />,
          )
        }
        {unpinViews?.length > 0 && <div
          onClick={() => {
            setMoreOpened(true);
          }}
          ref={moreButtonRef}
          className={'flex items-center w-full gap-2 rounded-[8px] px-2 py-1.5 text-sm cursor-pointer hover:bg-content-blue-50 focus:bg-content-blue-50 focus:outline-none'}
        >
          <MoreIcon className={'h-4 w-4 text-text-caption'} />
          <div>{t('button.more')}</div>

        </div>}
      </Collapse>
      }
      <Popover
        {...popoverOrigin}
        className={'appflowy-scroller'}
        sx={{
          maxHeight: '50vh',
        }}
        open={moreOpened} anchorEl={moreButtonRef.current}
        onClose={() => setMoreOpened(false)}
      >
        <div className={'flex w-[240px] flex-col gap-2 px-2 py-2'}>

          {groupByViews}
        </div>
      </Popover>

    </div>
  );
}

export default Favorite;