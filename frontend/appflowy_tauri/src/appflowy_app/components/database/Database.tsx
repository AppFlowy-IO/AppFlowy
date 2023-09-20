import { useRef } from 'react';
import { useSnapshot } from 'valtio';
import { DatabaseLayoutPB } from '@/services/backend';
import { VerticalScrollElementRefContext, DatabaseContext } from './database.context';
import { useViewId, useConnectDatabase,} from './database.hooks';
import { Grid } from './grid';

export const Database = () => {
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
        {/* TODO: how to get the title? */}
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
