import { DatabaseViewLayout, YjsDatabaseKey } from '@/application/types';
import { useDatabaseViewsSelector } from '@/application/database-yjs';
import CalendarSkeleton from '@/components/_shared/skeleton/CalendarSkeleton';
import GridSkeleton from '@/components/_shared/skeleton/GridSkeleton';
import KanbanSkeleton from '@/components/_shared/skeleton/KanbanSkeleton';
import { Board } from '@/components/database/board';
import { Calendar } from '@/components/database/calendar';
import { DatabaseConditionsContext } from '@/components/database/components/conditions/context';
import { DatabaseTabs } from '@/components/database/components/tabs';
import { Grid } from '@/components/database/grid';
import { ElementFallbackRender } from '@/components/error/ElementFallbackRender';
import React, { Suspense, useCallback, useMemo, useState } from 'react';
import { ErrorBoundary } from 'react-error-boundary';
import DatabaseConditions from 'src/components/database/components/conditions/DatabaseConditions';

function DatabaseViews ({
  onChangeView,
  viewId,
  iidIndex,
  viewName,
  visibleViewIds,
  hideConditions = false,
}: {
  onChangeView: (viewId: string) => void;
  viewId: string;
  iidIndex: string;
  viewName?: string;
  visibleViewIds?: string[];
  hideConditions?: boolean;
}) {
  const { childViews, viewIds } = useDatabaseViewsSelector(iidIndex, visibleViewIds);

  const value = useMemo(() => {
    return Math.max(
      0,
      viewIds.findIndex((id) => id === viewId),
    );
  }, [viewId, viewIds]);

  const [conditionsExpanded, setConditionsExpanded] = useState<boolean>(false);
  const toggleExpanded = useCallback(() => {
    setConditionsExpanded((prev) => !prev);
  }, []);

  const activeView = useMemo(() => {
    return childViews[value];
  }, [childViews, value]);

  const layout = useMemo(() => {
    if (!activeView) return null;
    return Number(activeView.get(YjsDatabaseKey.layout)) as DatabaseViewLayout;
  }, [activeView]);

  const view = useMemo(() => {
    switch (layout) {
      case DatabaseViewLayout.Grid:
        return <Grid />;
      case DatabaseViewLayout.Board:
        return <Board />;
      case DatabaseViewLayout.Calendar:
        return <Calendar />;
    }
  }, [layout]);

  const skeleton = useMemo(() => {
    switch (layout) {
      case DatabaseViewLayout.Grid:
        return <GridSkeleton
          includeTitle={false}
          includeTabs={false}
        />;
      case DatabaseViewLayout.Board:
        return <KanbanSkeleton
          includeTitle={false}
          includeTabs={false}
        />;
      case DatabaseViewLayout.Calendar:
        return <CalendarSkeleton
          includeTitle={false}
          includeTabs={false}
        />;
      default:
        return null;
    }
  }, [layout]);

  return (
    <>
      <DatabaseConditionsContext.Provider
        value={{
          expanded: conditionsExpanded,
          toggleExpanded,
        }}
      >
        <DatabaseTabs
          viewName={viewName}
          iidIndex={iidIndex}
          selectedViewId={viewId}
          setSelectedViewId={onChangeView}
          viewIds={viewIds}
          hideConditions={hideConditions}
        />
        {layout === DatabaseViewLayout.Calendar || hideConditions ? null : <DatabaseConditions />}
      </DatabaseConditionsContext.Provider>
      <div className={'flex h-full w-full flex-1 flex-col overflow-hidden'}>
        <Suspense fallback={skeleton}>
          <ErrorBoundary fallbackRender={ElementFallbackRender}>{view}</ErrorBoundary>
        </Suspense>
      </div>
    </>
  );
}

export default DatabaseViews;
