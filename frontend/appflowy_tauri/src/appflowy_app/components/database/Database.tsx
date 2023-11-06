import { useEffect, useState } from 'react';
import { useViewId } from '$app/hooks/ViewId.hooks';
import { databaseViewService } from './application';
import { DatabaseTabBar } from './components';
import { DatabaseLoader } from './DatabaseLoader';
import { DatabaseView } from './DatabaseView';
import { DatabaseCollection } from './components/database_settings';
import { PageController } from '$app/stores/effects/workspace/page/page_controller';

interface Props {
  selectedViewId?: string;
  setSelectedViewId?: (viewId: string) => void;
}

export const Database = ({ selectedViewId, setSelectedViewId }: Props) => {
  const viewId = useViewId();
  const [childViewIds, setChildViewIds] = useState<string[]>([]);

  useEffect(() => {
    const onPageChanged = () => {
      void databaseViewService.getDatabaseViews(viewId).then((value) => {
        setChildViewIds(value.map((view) => view.id));
      });
    };

    onPageChanged();

    const pageController = new PageController(viewId);

    void pageController.subscribe({
      onPageChanged,
    });

    return () => {
      void pageController.unsubscribe();
    };
  }, [viewId]);

  return (
    <DatabaseLoader viewId={selectedViewId || viewId}>
      <div className=''>
        <DatabaseTabBar
          pageId={viewId}
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
