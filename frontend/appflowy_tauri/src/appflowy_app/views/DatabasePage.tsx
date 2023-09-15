import { useRef } from 'react';
import { useSnapshot } from 'valtio';
import { DatabaseLayoutPB } from '@/services/backend';
import {
  VerticalScrollElementRefContext,
  DatabaseContext,
  Grid,
  useViewId,
  useConnectDatabase,
} from '../components/database';

export const DatabasePage = () => {
  const viewId = useViewId();
  const scrollElementRef = useRef<HTMLDivElement>(null);
  const database = useConnectDatabase(viewId);
  const snapshot = useSnapshot(database);

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
          <DatabaseContext.Provider value={database}>
            {snapshot.layoutType === DatabaseLayoutPB.Grid ? <Grid /> : null}
          </DatabaseContext.Provider>
        </VerticalScrollElementRefContext.Provider>
      </div>
    </div>
  );
};
