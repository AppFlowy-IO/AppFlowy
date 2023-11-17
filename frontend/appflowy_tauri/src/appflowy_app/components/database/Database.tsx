import { useEffect, useMemo, useState } from 'react';
import { useViewId } from '$app/hooks/ViewId.hooks';
import { databaseViewService } from './application';
import { DatabaseTabBar } from './components';
import { DatabaseLoader } from './DatabaseLoader';
import { DatabaseView } from './DatabaseView';
import { DatabaseCollection } from './components/database_settings';
import { PageController } from '$app/stores/effects/workspace/page/page_controller';
import SwipeableViews from 'react-swipeable-views';
import { TabPanel } from '$app/components/database/components/tab_bar/ViewTabs';
import { useDatabaseResize } from '$app/components/database/Database.hooks';

interface Props {
  selectedViewId?: string;
  setSelectedViewId?: (viewId: string) => void;
}

export const Database = ({ selectedViewId, setSelectedViewId }: Props) => {
  const viewId = useViewId();
  const [childViewIds, setChildViewIds] = useState<string[]>([]);
  const { ref, collectionRef, tableHeight } = useDatabaseResize();

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

  const index = useMemo(() => {
    return Math.max(0, childViewIds.indexOf(selectedViewId ?? viewId));
  }, [childViewIds, selectedViewId, viewId]);

  return (
    <div ref={ref} className='appflowy-database flex flex-1 flex-col overflow-y-hidden'>
      <DatabaseTabBar
        pageId={viewId}
        setSelectedViewId={setSelectedViewId}
        selectedViewId={selectedViewId}
        childViewIds={childViewIds}
      />
      <SwipeableViews
        slideStyle={{
          overflow: 'hidden',
        }}
        className={'flex-1 overflow-hidden'}
        axis={'x'}
        index={index}
      >
        {childViewIds.map((id) => (
          <TabPanel key={id} index={index} value={index}>
            <DatabaseLoader viewId={id}>
              <div ref={collectionRef}>
                <DatabaseCollection />
              </div>

              <DatabaseView isActivated={selectedViewId === id} tableHeight={tableHeight} />
            </DatabaseLoader>
          </TabPanel>
        ))}
      </SwipeableViews>
    </div>
  );
};
