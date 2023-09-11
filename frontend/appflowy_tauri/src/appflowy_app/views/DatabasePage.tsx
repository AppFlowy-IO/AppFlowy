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
  const verticalScrollElementRef = useRef<HTMLDivElement>(null);
  const database = useConnectDatabase(viewId);
  const snapshot = useSnapshot(database);

  return (
    <div
      ref={verticalScrollElementRef}
      className="h-full overflow-y-auto"
    >
      <div className="px-16 pt-8 mb-6">
        <h1 className="text-3xl font-semibold">Grid</h1>
      </div>
      <VerticalScrollElementRefContext.Provider value={verticalScrollElementRef}>
        <DatabaseContext.Provider value={database}>
          {snapshot.layoutType === DatabaseLayoutPB.Grid ? <Grid /> : null}
        </DatabaseContext.Provider>
      </VerticalScrollElementRefContext.Provider>
    </div>
  );
};
