import { useRef } from 'react';
import { proxy, useSnapshot } from 'valtio';
import { DatabaseLayoutPB } from '@/services/backend';
import { DndContext, DndContextDescriptor, useAutoScrollOnEdge } from './_shared';
import { VerticalScrollElementRefContext, DatabaseContext, DatabaseUIStateDescriptor, DatabaseUIState } from './database.context';
import { useViewId, useConnectDatabase, } from './database.hooks';
import { Grid } from './grid';

export const Database = () => {
  const viewId = useViewId();
  const verticalScrollElementRef = useRef<HTMLDivElement>(null);
  const database = useConnectDatabase(viewId);
  const snapshot = useSnapshot(database);
  const dndContext = useRef(proxy<DndContextDescriptor>({
    dragging: undefined,
  }));
  const uiState = useRef<DatabaseUIStateDescriptor>(proxy({
    enableVerticalAutoScroll: false,
    enableHorizontalAutoScroll: false,
  }));
  const { enableVerticalAutoScroll } = useSnapshot(uiState.current);

  const listeners = useAutoScrollOnEdge({
    trigger: 'drag',
    vertical: true,
    disabled: !enableVerticalAutoScroll,
  });

  return (
    <div
      ref={verticalScrollElementRef}
      className="h-full overflow-y-auto"
      {...listeners}
    >
      <div className="px-16 pt-8 mb-6">
        {/* TODO: how to get the title? */}
        <h1 className="text-3xl font-semibold">Grid</h1>
      </div>
      <VerticalScrollElementRefContext.Provider value={verticalScrollElementRef}>
        <DndContext.Provider value={dndContext.current}>
          <DatabaseContext.Provider value={database}>
            <DatabaseUIState.Provider value={uiState.current}>
              {snapshot.layoutType === DatabaseLayoutPB.Grid ? <Grid /> : null}
            </DatabaseUIState.Provider>
          </DatabaseContext.Provider>
        </DndContext.Provider >
      </VerticalScrollElementRefContext.Provider>
    </div>
  );
};
