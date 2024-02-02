import React, { forwardRef, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useViewId } from '$app/hooks/ViewId.hooks';
import { databaseViewService } from '$app/application/database';
import { DatabaseTabBar } from './components';
import { DatabaseLoader } from './DatabaseLoader';
import { DatabaseView } from './DatabaseView';
import { DatabaseCollection } from './components/database_settings';
import SwipeableViews from 'react-swipeable-views';
import { TabPanel } from '$app/components/database/components/tab_bar/ViewTabs';
import DatabaseSettings from '$app/components/database/components/database_settings/DatabaseSettings';
import { Portal } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { ErrorCode, FolderNotification } from '@/services/backend';
import ExpandRecordModal from '$app/components/database/components/edit_record/ExpandRecordModal';
import { subscribeNotifications } from '$app/application/notification';

interface Props {
  selectedViewId?: string;
  setSelectedViewId?: (viewId: string) => void;
}

export const Database = forwardRef<HTMLDivElement, Props>(({ selectedViewId, setSelectedViewId }, ref) => {
  const innerRef = useRef<HTMLDivElement>();
  const databaseRef = (ref ?? innerRef) as React.MutableRefObject<HTMLDivElement>;

  const viewId = useViewId();
  const { t } = useTranslation();
  const [notFound, setNotFound] = useState(false);
  const [childViewIds, setChildViewIds] = useState<string[]>([]);
  const [editRecordRowId, setEditRecordRowId] = useState<string | null>(null);
  const [openCollections, setOpenCollections] = useState<string[]>([]);

  const handleResetDatabaseViews = useCallback(async (viewId: string) => {
    await databaseViewService
      .getDatabaseViews(viewId)
      .then((value) => {
        setChildViewIds(value.map((view) => view.id));
      })
      .catch((err) => {
        if (err.code === ErrorCode.RecordNotFound) {
          setNotFound(true);
        }
      });
  }, []);

  useEffect(() => {
    void handleResetDatabaseViews(viewId);
    const unsubscribePromise = subscribeNotifications(
      {
        [FolderNotification.DidUpdateChildViews]: (changeset) => {
          if (changeset.create_child_views.length === 0 && changeset.delete_child_views.length === 0) {
            return;
          }

          void handleResetDatabaseViews(viewId);
        },
      },
      {
        id: viewId,
      }
    );

    return () => void unsubscribePromise.then((unsubscribe) => unsubscribe());
  }, [handleResetDatabaseViews, viewId]);

  const value = useMemo(() => {
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
    [openCollections, setOpenCollections]
  );

  const onEditRecord = useCallback(
    (rowId: string) => {
      setEditRecordRowId(rowId);
    },
    [setEditRecordRowId]
  );

  if (notFound) {
    return (
      <div className='mb-2 flex h-full w-full items-center justify-center rounded border border-dashed border-line-divider'>
        <p className={'text-xl text-text-caption'}>{t('deletePagePrompt.text')}</p>
      </div>
    );
  }

  return (
    <div ref={databaseRef} className='appflowy-database relative flex flex-1 flex-col overflow-y-hidden'>
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
        index={value}
      >
        {childViewIds.map((id, index) => (
          <TabPanel className={'flex h-full w-full flex-col'} key={id} index={index} value={value}>
            <DatabaseLoader viewId={id}>
              {selectedViewId === id && (
                <>
                  <Portal container={databaseRef.current}>
                    <div className={'absolute right-16 top-0 py-1'}>
                      <DatabaseSettings
                        onToggleCollection={(forceOpen?: boolean) => onToggleCollection(id, forceOpen)}
                      />
                    </div>
                  </Portal>
                  <DatabaseCollection open={openCollections.includes(id)} />
                  {editRecordRowId && (
                    <ExpandRecordModal
                      rowId={editRecordRowId}
                      open={Boolean(editRecordRowId)}
                      onClose={() => {
                        setEditRecordRowId(null);
                      }}
                    />
                  )}
                </>
              )}

              <DatabaseView onEditRecord={onEditRecord} />
            </DatabaseLoader>
          </TabPanel>
        ))}
      </SwipeableViews>
    </div>
  );
});
