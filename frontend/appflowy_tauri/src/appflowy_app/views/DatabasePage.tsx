import { useEffect, useRef } from 'react';
import { useParams } from 'react-router-dom';
import { useSnapshot } from 'valtio';
import { DatabaseLayoutPB } from '@/services/backend';
import { readDatabase, database } from '$app/stores/database';
import { VerticalScrollElementRefContext, Grid } from '../components/database/grid';

export const DatabasePage = () => {
  const viewId = useParams().id;
  const scrollElementRef = useRef<HTMLDivElement>(null);
  const snapshot = useSnapshot(database);

  useEffect(() => {
    if (!viewId) {
      return;
    }

    const closePromise = readDatabase(viewId);

    return () => {
      void closePromise.then(close => close());
    };
  }, [viewId]);

  return (
    <div
      ref={scrollElementRef}
      className="scroll-container flex flex-col overflow-y-auto overflow-x-hidden h-full"
    >
      <div>
        <div className="px-16 pt-8">
          <h1 className="text-3xl font-semibold mb-6">Grid</h1>
          <div className="text-lg font-semibold mb-9">
            👋  Welcome to AppFlowy
          </div>
        </div>
        <VerticalScrollElementRefContext.Provider value={scrollElementRef}>
          {snapshot.layoutType === DatabaseLayoutPB.Grid
            ? <Grid />
            : null}
        </VerticalScrollElementRefContext.Provider>
      </div>
    </div>
  );
};
