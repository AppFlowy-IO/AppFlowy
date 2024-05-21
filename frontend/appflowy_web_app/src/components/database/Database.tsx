import { DatabaseViewLayout, YDatabase, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import { useId } from '@/components/_shared/context-provider/IdProvider';
import RecordNotFound from '@/components/_shared/not-found/RecordNotFound';
import { AFConfigContext } from '@/components/app/AppConfig';
import { Board } from '@/components/database/board';
import { Calendar } from '@/components/database/calendar';
import { DatabaseConditionsContext } from '@/components/database/components/conditions/context';
import { Grid } from '@/components/database/grid';
import { DatabaseTabs, TabPanel } from '@/components/database/components/tabs';
import { DatabaseContextProvider } from '@/components/database/DatabaseContext';
import DatabaseTitle from '@/components/database/DatabaseTitle';
import { Log } from '@/utils/log';
import CircularProgress from '@mui/material/CircularProgress';
import React, { memo, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import SwipeableViews from 'react-swipeable-views';
import DatabaseConditions from 'src/components/database/components/conditions/DatabaseConditions';
import * as Y from 'yjs';

export const Database = memo(() => {
  const { objectId, workspaceId } = useId() || {};
  const [search, setSearch] = useSearchParams();
  const viewId = search.get('v');

  const [doc, setDoc] = useState<YDoc | null>(null);
  const [rows, setRows] = useState<Y.Map<YDoc> | null>(null); // Map<rowId, YDoc
  const [notFound, setNotFound] = useState<boolean>(false);
  const databaseService = useContext(AFConfigContext)?.service?.databaseService;

  const handleOpenDocument = useCallback(async () => {
    if (!databaseService || !workspaceId || !objectId) return;

    try {
      setDoc(null);
      const { databaseDoc, rows } = await databaseService.openDatabase(workspaceId, objectId);

      console.log('databaseDoc', databaseDoc.getMap(YjsEditorKey.data_section).toJSON());
      setDoc(databaseDoc);
      setRows(rows);
    } catch (e) {
      Log.error(e);
      setNotFound(true);
    }
  }, [databaseService, workspaceId, objectId]);

  useEffect(() => {
    setNotFound(false);
    void handleOpenDocument();
  }, [handleOpenDocument]);

  const database = useMemo(() => doc?.getMap(YjsEditorKey.data_section).get(YjsEditorKey.database) as YDatabase, [doc]);

  const views = useMemo(() => database?.get(YjsDatabaseKey.views), [database]);

  const handleChangeView = useCallback(
    (viewId: string) => {
      setSearch({ v: viewId });
    },
    [setSearch]
  );

  const viewIds = useMemo(() => (views ? Array.from(views.keys()) : []), [views]);

  const value = useMemo(() => {
    return Math.max(
      0,
      viewIds.findIndex((id) => id === (viewId ?? objectId))
    );
  }, [viewId, viewIds, objectId]);

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

  console.log('viewId', viewId, 'objectId', doc, objectId, database);
  if (!objectId) return null;

  if (!doc) {
    return <RecordNotFound open={notFound} workspaceId={workspaceId} />;
  }

  if (!rows) {
    return (
      <div className={'flex h-full w-full items-center justify-center'}>
        <CircularProgress />
      </div>
    );
  }

  return (
    <div className={'relative flex h-full w-full flex-col'}>
      <DatabaseTitle viewId={objectId} />
      <div className='appflowy-database relative flex w-full flex-1 select-text flex-col overflow-y-hidden'>
        <DatabaseContextProvider viewId={viewId || objectId} doc={doc} rowDocMap={rows} readOnly={true}>
          <DatabaseConditionsContext.Provider
            value={{
              expanded: conditionsExpanded,
              toggleExpanded,
            }}
          >
            <DatabaseTabs selectedViewId={viewId || objectId} setSelectedViewId={handleChangeView} viewIds={viewIds} />
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
            {viewIds.map((viewId, index) => {
              const layout = Number(views.get(viewId)?.get(YjsDatabaseKey.layout)) as DatabaseViewLayout;
              const Component = getDatabaseViewComponent(layout);

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
        </DatabaseContextProvider>
      </div>
    </div>
  );
});

export default Database;
