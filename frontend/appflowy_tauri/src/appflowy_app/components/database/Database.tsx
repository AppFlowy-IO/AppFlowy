import { useEffect, useMemo, useState } from 'react';
import { useViewId } from '$app/hooks';
import { DatabaseView as DatabaseViewType, databaseViewService } from './application';
import { DatabaseTabBar } from './components';
import { useSelectDatabaseView } from './Database.hooks';
import { DatabaseLoader } from './DatabaseLoader';
import { DatabaseView } from './DatabaseView';
import { DatabaseSettings } from './components/database_settings';

export const Database = () => {
  const viewId = useViewId();
  const [views, setViews] = useState<DatabaseViewType[]>([]);
  const [selectedViewId, selectViewId] = useSelectDatabaseView();
  const activeView = useMemo(() => views?.find((view) => view.id === selectedViewId), [views, selectedViewId]);

  useEffect(() => {
    setViews([]);
    void databaseViewService.getDatabaseViews(viewId).then((value) => {
      setViews(value);
    });
  }, [viewId]);

  useEffect(() => {
    if (!activeView) {
      const firstViewId = views?.[0]?.id;

      if (firstViewId) {
        selectViewId(firstViewId);
      }
    }
  }, [views, activeView, selectViewId]);

  return activeView ? (
    <DatabaseLoader viewId={viewId}>
      <div className='px-16'>
        <DatabaseTabBar views={views} />
        <DatabaseSettings />
      </div>
      <DatabaseView />
    </DatabaseLoader>
  ) : null;
};
