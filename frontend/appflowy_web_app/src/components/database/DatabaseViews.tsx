import { DatabaseViewLayout, YjsDatabaseKey } from '@/application/collab.type';
import { useDatabaseViewsSelector } from '@/application/database-yjs';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import { Board } from '@/components/database/board';
import { Calendar } from '@/components/database/calendar';
import { DatabaseConditionsContext } from '@/components/database/components/conditions/context';
import { DatabaseTabs } from '@/components/database/components/tabs';
import { Grid } from '@/components/database/grid';
import { ElementFallbackRender } from '@/components/error/ElementFallbackRender';
import React, { Suspense, useCallback, useMemo, useState } from 'react';
import { ErrorBoundary } from 'react-error-boundary';
import DatabaseConditions from 'src/components/database/components/conditions/DatabaseConditions';

function DatabaseViews({
  onChangeView,
  viewId,
  iidIndex,
  viewName,
}: {
  onChangeView: (viewId: string) => void;
  viewId: string;
  iidIndex: string;
  viewName?: string;
}) {
  const { childViews, viewIds } = useDatabaseViewsSelector(iidIndex);

  const value = useMemo(() => {
    return Math.max(
      0,
      viewIds.findIndex((id) => id === viewId)
    );
  }, [viewId, viewIds]);

  const [conditionsExpanded, setConditionsExpanded] = useState<boolean>(false);
  const toggleExpanded = useCallback(() => {
    setConditionsExpanded((prev) => !prev);
  }, []);

  const activeView = useMemo(() => {
    return childViews[value];
  }, [childViews, value]);

  const view = useMemo(() => {
    if (!activeView) return null;
    const layout = Number(activeView.get(YjsDatabaseKey.layout)) as DatabaseViewLayout;

    switch (layout) {
      case DatabaseViewLayout.Grid:
        return <Grid />;
      case DatabaseViewLayout.Board:
        return <Board />;
      case DatabaseViewLayout.Calendar:
        return <Calendar />;
    }
  }, [activeView]);

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
        />
        <DatabaseConditions />
      </DatabaseConditionsContext.Provider>
      <div className={'flex h-full w-full flex-1 flex-col overflow-hidden'}>
        <Suspense fallback={<ComponentLoading />}>
          <ErrorBoundary fallbackRender={ElementFallbackRender}>{view}</ErrorBoundary>
        </Suspense>
      </div>
    </>
  );
}

export default DatabaseViews;
