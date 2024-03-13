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
import { Page } from '$app_reducers/pages/slice';
import { getPage } from '$app/application/folder/page.service';
import './database.scss';

interface Props {
  selectedViewId?: string;
  setSelectedViewId?: (viewId: string) => void;
}

export const Database = forwardRef<HTMLDivElement, Props>(({ selectedViewId, setSelectedViewId }, ref) => {
  const innerRef = useRef<HTMLDivElement>();
  const databaseRef = (ref ?? innerRef) as React.MutableRefObject<HTMLDivElement>;
  const viewId = useViewId();
  const [settingDom, setSettingDom] = useState<HTMLDivElement | null>(null);

  const [page, setPage] = useState<Page | null>(null);
  const { t } = useTranslation();
  const [notFound, setNotFound] = useState(false);
  const [childViews, setChildViews] = useState<Page[]>([]);
  const [editRecordRowId, setEditRecordRowId] = useState<string | null>(null);
  const [openCollections, setOpenCollections] = useState<string[]>([]);

  const handleResetDatabaseViews = useCallback(async (viewId: string) => {
    await databaseViewService
      .getDatabaseViews(viewId)
      .then((value) => {
        setChildViews(value);
      })
      .catch((err) => {
        if (err.code === ErrorCode.RecordNotFound) {
          setNotFound(true);
        }
      });
  }, []);

  const handleGetPage = useCallback(async () => {
    try {
      const page = await getPage(viewId);

      setPage(page);
    } catch (e) {
      setNotFound(true);
    }
  }, [viewId]);

  const parentId = page?.parentId;

  useEffect(() => {
    void handleGetPage();
    void handleResetDatabaseViews(viewId);
    const unsubscribePromise = subscribeNotifications({
      [FolderNotification.DidUpdateView]: (changeset) => {
        if (changeset.parent_view_id !== viewId && changeset.id !== viewId) return;
        setChildViews((prev) => {
          const index = prev.findIndex((view) => view.id === changeset.id);

          if (index === -1) {
            return prev;
          }

          const newViews = [...prev];

          newViews[index] = {
            ...newViews[index],
            name: changeset.name,
          };

          return newViews;
        });
      },
      [FolderNotification.DidUpdateChildViews]: (changeset) => {
        if (changeset.parent_view_id !== viewId && changeset.parent_view_id !== parentId) return;
        if (changeset.create_child_views.length === 0 && changeset.delete_child_views.length === 0) {
          return;
        }

        void handleResetDatabaseViews(viewId);
      },
    });

    return () => void unsubscribePromise.then((unsubscribe) => unsubscribe());
  }, [handleGetPage, handleResetDatabaseViews, viewId, parentId]);

  const value = useMemo(() => {
    return Math.max(
      0,
      childViews.findIndex((view) => view.id === (selectedViewId ?? viewId))
    );
  }, [childViews, selectedViewId, viewId]);

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
    <div
      ref={databaseRef}
      className='appflowy-database relative flex w-full flex-1 select-none flex-col overflow-y-hidden'
    >
      <DatabaseTabBar
        pageId={viewId}
        setSelectedViewId={setSelectedViewId}
        selectedViewId={selectedViewId}
        childViews={childViews}
        ref={setSettingDom}
      />
      <SwipeableViews
        slideStyle={{
          overflow: 'hidden',
        }}
        className={'flex-1 overflow-hidden'}
        axis={'x'}
        index={value}
      >
        {childViews.map((view, index) => (
          <TabPanel
            data-view-id={view.id}
            className={'flex h-full w-full flex-col'}
            key={view.id}
            index={index}
            value={value}
          >
            <DatabaseLoader viewId={view.id}>
              {selectedViewId === view.id && (
                <>
                  {settingDom && (
                    <Portal container={settingDom}>
                      <DatabaseSettings
                        onToggleCollection={(forceOpen?: boolean) => onToggleCollection(view.id, forceOpen)}
                      />
                    </Portal>
                  )}

                  <DatabaseCollection open={openCollections.includes(view.id)} />
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
