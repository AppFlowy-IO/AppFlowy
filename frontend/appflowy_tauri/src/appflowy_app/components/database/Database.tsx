import { useEffect, useRef, useState } from 'react';
import { proxy } from 'valtio';
import { subscribeKey } from 'valtio/utils';
import { DatabaseLayoutPB } from '@/services/backend';
import { DndContext, DndContextDescriptor } from './_shared';
import { VerticalScrollElementRefContext, DatabaseContext } from './database.context';
import { useViewId, useConnectDatabase } from './database.hooks';
import { DatabaseHeader } from './DatabaseHeader';
import { Grid } from './grid';

export const Database = () => {
  const viewId = useViewId();
  const verticalScrollElementRef = useRef<HTMLDivElement>(null);
  const database = useConnectDatabase(viewId);
  const [ layoutType, setLayoutType ] = useState(database.layoutType);
  const dndContext = useRef(proxy<DndContextDescriptor>({
    dragging: null,
  }));

  useEffect(() => {
    return subscribeKey(database, 'layoutType', (value) => {
      setLayoutType(value);
    });
  }, [database]);

  return (
    <div
      ref={verticalScrollElementRef}
      className="h-full overflow-y-auto"
    >
      <DatabaseHeader />
      <VerticalScrollElementRefContext.Provider value={verticalScrollElementRef}>
        <DndContext.Provider value={dndContext.current}>
          <DatabaseContext.Provider value={database}>
            {layoutType === DatabaseLayoutPB.Grid ? <Grid /> : null}
          </DatabaseContext.Provider>
        </DndContext.Provider >
      </VerticalScrollElementRefContext.Provider>
    </div>
  );
};
