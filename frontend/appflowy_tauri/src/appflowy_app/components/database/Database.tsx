import { useEffect, useState } from 'react';
import { useViewId } from '$app/hooks/ViewId.hooks';
import { databaseViewService } from './application';
import { DatabaseTabBar } from './components';
import { DatabaseLoader } from './DatabaseLoader';
import { DatabaseView } from './DatabaseView';
import { DatabaseCollection } from './components/database_settings';

interface Props {
  selectedViewId?: string;
  setSelectedViewId?: (viewId: string) => void;
}

export const Database = ({ selectedViewId, setSelectedViewId }: Props) => {
  const viewId = useViewId();
  const [childViewIds, setChildViewIds] = useState<string[]>([]);

  useEffect(() => {
    void databaseViewService.getDatabaseViews(viewId).then((value) => {
      setChildViewIds(value.map((view) => view.id));
    });
  }, [viewId]);

  return (
    <DatabaseLoader viewId={selectedViewId || viewId}>
      <div className=''>
        <DatabaseTabBar
          setSelectedViewId={setSelectedViewId}
          selectedViewId={selectedViewId}
          childViewIds={childViewIds}
        />
        <DatabaseCollection />
      </div>
      <DatabaseView />
    </DatabaseLoader>
  );
};
