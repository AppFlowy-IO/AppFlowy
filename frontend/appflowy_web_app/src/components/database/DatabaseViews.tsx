import { DatabaseViewLayout, YjsDatabaseKey } from '@/application/collab.type';
import { useDatabaseViewsSelector } from '@/application/database-yjs';
import { Board } from '@/components/database/board';
import { Calendar } from '@/components/database/calendar';
import { DatabaseConditionsContext } from '@/components/database/components/conditions/context';
import { DatabaseTabs, TabPanel } from '@/components/database/components/tabs';
import { Grid } from '@/components/database/grid';
import React, { useCallback, useMemo, useState } from 'react';
import SwipeableViews from 'react-swipeable-views';
import DatabaseConditions from 'src/components/database/components/conditions/DatabaseConditions';

function DatabaseViews({
  onChangeView,
  currentViewId,
}: {
  onChangeView: (viewId: string) => void;
  currentViewId: string;
}) {
  const { childViews, viewIds } = useDatabaseViewsSelector();

  const value = useMemo(() => {
    return Math.max(
      0,
      viewIds.findIndex((id) => id === currentViewId)
    );
  }, [currentViewId, viewIds]);

  const getDatabaseViewComponent = useCallback((layout: DatabaseViewLayout) => {
    switch (layout) {
      case DatabaseViewLayout.Grid:
        return Grid;
      case DatabaseViewLayout.Board:
        return Board;
      case DatabaseViewLayout.Calendar:
        return Calendar;
    }
  }, []);

  const [conditionsExpanded, setConditionsExpanded] = useState<boolean>(false);
  const toggleExpanded = useCallback(() => {
    setConditionsExpanded((prev) => !prev);
  }, []);

  return (
    <>
      <DatabaseConditionsContext.Provider
        value={{
          expanded: conditionsExpanded,
          toggleExpanded,
        }}
      >
        <DatabaseTabs selectedViewId={currentViewId} setSelectedViewId={onChangeView} viewIds={viewIds} />
        <DatabaseConditions />
      </DatabaseConditionsContext.Provider>
      <SwipeableViews
        slideStyle={{
          overflow: 'hidden',
        }}
        className={'h-full w-full flex-1 overflow-hidden'}
        axis={'x'}
        index={value}
        containerStyle={{ height: '100%' }}
      >
        {childViews.map((view, index) => {
          const layout = Number(view.get(YjsDatabaseKey.layout)) as DatabaseViewLayout;
          const Component = getDatabaseViewComponent(layout);
          const viewId = viewIds[index];

          return (
            <TabPanel
              data-view-id={viewId}
              className={'flex h-full w-full flex-col'}
              key={viewId}
              index={index}
              value={value}
            >
              <Component />
            </TabPanel>
          );
        })}
      </SwipeableViews>
    </>
  );
}

export default DatabaseViews;
