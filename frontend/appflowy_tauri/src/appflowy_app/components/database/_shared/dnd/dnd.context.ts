import { createContext } from 'react';
import { proxy } from 'valtio';

export interface DragItem<T = Record<string, unknown>> {
  type: string;
  data: T;
}

export interface DndContextDescriptor {
  dragging: DragItem | null,
}

const defaultDndContext: DndContextDescriptor = proxy({
  dragging: null,
});

export const DndContext = createContext<DndContextDescriptor>(defaultDndContext);
