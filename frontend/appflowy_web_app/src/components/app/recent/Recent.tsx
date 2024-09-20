import { UIVariant } from '@/application/types';
import OutlineItem from '@/components/_shared/outline/OutlineItem';
import RecentListSkeleton from '@/components/_shared/skeleton/RecentListSkeleton';
import { useAppHandlers, useAppRecent } from '@/components/app/app.hooks';
import dayjs from 'dayjs';
import { groupBy, sortBy } from 'lodash-es';
import React, { useEffect, useMemo } from 'react';
import { useTranslation } from 'react-i18next';

enum RecentGroup {
  today = 'today',
  thisWeek = 'thisWeek',
  Others = 'Others',
}

export function Recent () {
  const {
    recentViews,
    loadRecentViews,
  } = useAppRecent();
  const navigateToView = useAppHandlers().toView;
  const { t } = useTranslation();

  useEffect(() => {
    void loadRecentViews?.();
  }, [loadRecentViews]);

  const groupByViewsWithDay = useMemo(() => {
    return groupBy(recentViews, (view) => {
      const date = dayjs(view.last_edited_time);
      const today = date.isSame(dayjs(), 'day');
      const thisWeek = date.isSame(dayjs(), 'week');

      if (today) return RecentGroup.today;
      if (thisWeek) return RecentGroup.thisWeek;
      return RecentGroup.Others;
    });
  }, [recentViews]);

  const groupByViews = useMemo(() => {
    return sortBy(Object.entries(groupByViewsWithDay), ([key]) => {
      return key === RecentGroup.today ? 0 : key === RecentGroup.thisWeek ? 1 : 2;
    }).map(([key, value]) => {
      const timeLabel: Record<string, string> = {
        [RecentGroup.today]: t('sideBar.today'),
        [RecentGroup.thisWeek]: t('sideBar.thisWeek'),
        [RecentGroup.Others]: t('sideBar.earlier'),
      };

      return <div className={'flex flex-col gap-2'} key={key}>
        <div className={'text-xs text-text-caption py-1 px-1'}>{timeLabel[key]}</div>
        <div className={'px-1'}>
          {value.map((view) =>
            <OutlineItem
              variant={UIVariant.Recent}
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
    <div className={'flex w-[268px] flex-col gap-1 py-[10px] px-[10px]'}>
      <div className={'flex h-fit my-0.5 w-full flex-col gap-2'}>
        <div
          className={
            'flex items-center w-full gap-0.5 px-1 rounded-[8px] pb-1 text-sm'
          }
        >
          <div className={'flex-1 truncate text-text-caption'}>{t('sideBar.recent')}</div>
        </div>
      </div>

      {recentViews && recentViews.length > 0 ?
        groupByViews : <RecentListSkeleton />
      }

    </div>
  );
}

export default Recent;