import React from 'react';
import TabbarSkeleton from '@/components/_shared/skeleton/TabbarSkeleton';
import TitleSkeleton from '@/components/_shared/skeleton/TitleSkeleton';

function CalendarSkeleton ({ includeTitle = true, includeTabs = true }: {
  includeTitle?: boolean;
  includeTabs?: boolean
}) {
  const daysInWeek = 7;
  const weeksInMonth = 4;

  return (
    <div className={`w-full overflow-x-auto ${includeTitle ? 'py-2 px-6' : ''}`}>
      {includeTitle && (
        <>
          <div className="w-full my-6 flex items-center h-20 mb-2">
            <TitleSkeleton />
          </div>
        </>
      )}

      {includeTabs && <div className="w-full flex items-center h-10 mb-2">
        <TabbarSkeleton />
      </div>}
      {/* Calendar Header */}
      <div className="flex justify-between items-center mb-2">
        <div className="w-24 h-10 bg-fill-list-hover rounded animate-pulse"></div>
        <div className="flex gap-1">
          <div className="w-10 h-10 bg-fill-list-hover rounded animate-pulse"></div>
          <div className="w-10 h-10 bg-fill-list-hover rounded animate-pulse"></div>
        </div>
      </div>

      {/* Weekday Names */}
      <div className="grid grid-cols-7 gap-1 mb-1">
        {[...Array(daysInWeek)].map((_, index) => (
          <div key={index} className="h-8 bg-fill-list-hover rounded animate-pulse"></div>
        ))}
      </div>

      {/* Calendar Grid */}
      <div className="border border-line-divider rounded shadow">
        <div className="grid grid-cols-7">
          {[...Array(weeksInMonth * daysInWeek)].map((_, index) => (
            <div key={index} className="aspect-square p-1 border-r border-b border-line-divider">
              <div className="h-full flex flex-col">
                <div className="w-1/3 h-5 bg-fill-list-hover rounded animate-pulse self-end"></div>
                <div className="flex-1 flex flex-col justify-center mt-1">
                  <div className="w-4/5 h-4 bg-fill-list-hover rounded animate-pulse mb-0.5"></div>
                  <div className="w-3/5 h-4 bg-fill-list-hover rounded animate-pulse"></div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default CalendarSkeleton;