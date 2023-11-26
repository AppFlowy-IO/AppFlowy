import React, { useCallback, useEffect, useMemo, useState } from 'react';
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
import DatabaseSettings from '$app/components/database/components/database_settings/DatabaseSettings';
import { Portal } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { ErrorCode } from '@/services/backend';

interface Props {
  selectedViewId?: string;
  setSelectedViewId?: (viewId: string) => void;
}

export const Database = ({ selectedViewId, setSelectedViewId }: Props) => {
  const viewId = useViewId();
  const { t } = useTranslation();
  const [notFound, setNotFound] = useState(false);
  const [childViewIds, setChildViewIds] = useState<string[]>([]);
  const { ref, collectionRef, tableHeight } = useDatabaseResize();
  const [openCollections, setOpenCollections] = useState<string[]>([]);

  useEffect(() => {
    const onPageChanged = () => {
      void databaseViewService
        .getDatabaseViews(viewId)
        .then((value) => {
          setChildViewIds(value.map((view) => view.id));
        })
        .catch((err) => {
          if (err.code === ErrorCode.RecordNotFound) {
            setNotFound(true);
          }
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

  const onToggleCollection = useCallback(
    (id: string, forceOpen?: boolean) => {
      if (forceOpen) {
        setOpenCollections((prev) => {
          if (prev.includes(id)) {
            return prev;
          }

          return [...prev, id];
        });
        return;
      }

      if (openCollections.includes(id)) {
        setOpenCollections((prev) => prev.filter((item) => item !== id));
      } else {
        setOpenCollections((prev) => [...prev, id]);
      }
    },
    [openCollections]
  );

  if (notFound) {
    return (
      <div className='mb-2 flex h-full w-full items-center justify-center rounded border border-dashed border-line-divider'>
        <p className={'text-xl text-text-caption'}>{t('deletePagePrompt.text')}</p>
      </div>
    );
  }

  return (
    <div ref={ref} className='appflowy-database relative flex flex-1 flex-col overflow-y-hidden'>
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
              {selectedViewId === id && (
                <>
                  <Portal container={ref.current}>
                    <div className={'absolute right-16 top-0 py-1'}>
                      <DatabaseSettings
                        onToggleCollection={(forceOpen?: boolean) => onToggleCollection(id, forceOpen)}
                      />
                    </div>
                  </Portal>
                  <div ref={collectionRef}>
                    <DatabaseCollection open={openCollections.includes(id)} />
                  </div>
                </>
              )}

              <DatabaseView isActivated={selectedViewId === id} tableHeight={tableHeight} />
            </DatabaseLoader>
          </TabPanel>
        ))}
      </SwipeableViews>
    </div>
  );
};
