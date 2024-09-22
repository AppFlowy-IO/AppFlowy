import TabbarSkeleton from '@/components/_shared/skeleton/TabbarSkeleton';
import TitleSkeleton from '@/components/_shared/skeleton/TitleSkeleton';
import React from 'react';

function KanbanSkeleton ({
  includeTitle = true,
  includeTabs = true,
}: {
  includeTitle?: boolean;
  includeTabs?: boolean;
}) {
  const columns = Math.max(Math.ceil(window.innerWidth / 420), 3);
  const cardsPerColumn = Math.max(Math.ceil(window.innerHeight / 300), 3);

  return (
    <div className={`w-full overflow-x-auto py-${includeTitle ? '2' : '0'} px-${includeTitle ? '6' : '0'}`}>
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

      <div className="w-full mt-2">
        <div className="flex space-x-4">
          {[...Array(columns)].map((_, columnIndex) => (
            <div key={columnIndex} className="min-w-[280px] bg-bg-body shadow-md rounded-lg p-4 flex flex-col">
              {/* Column title */}
              <div className="h-8 bg-fill-list-hover rounded w-3/5 mb-4 animate-pulse"></div>

              {/* Cards */}
              {[...Array(cardsPerColumn)].map((_, cardIndex) => (
                <div key={cardIndex} className="bg-bg-base rounded-lg p-4 mb-4 shadow">
                  <div className="h-5 bg-fill-list-hover rounded w-full mb-2 animate-pulse"></div>
                  <div className="h-4 bg-fill-list-hover rounded w-4/5 animate-pulse"></div>
                  <div className="mt-4 flex justify-between items-center">
                    <div className="h-8 w-8 bg-fill-list-hover rounded-full animate-pulse"></div>
                    <div className="h-4 w-16 bg-fill-list-hover rounded animate-pulse"></div>
                  </div>
                </div>
              ))}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default KanbanSkeleton;