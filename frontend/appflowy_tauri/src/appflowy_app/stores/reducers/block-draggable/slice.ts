import { createSlice, PayloadAction } from '@reduxjs/toolkit';

const DRAG_DISTANCE_THRESHOLD = 10;

export enum BlockDraggableType {
  BLOCK = 'BLOCK',
  PAGE = 'PAGE',
}

export interface DraggableContext {
  type: BlockDraggableType;
  contextId?: string;
}
export interface BlockDraggableState {
  dragging: boolean;
  startDraggingPosition?: {
    x: number;
    y: number;
  };
  draggingPosition?: {
    x: number;
    y: number;
  };
  isDraggable: boolean;
  dragShadowVisible: boolean;
  draggingId?: string;
  insertType?: DragInsertType;
  dropId?: string;
  dropContext?: DraggableContext;
  draggingContext?: DraggableContext;
}

export enum DragInsertType {
  BEFORE = 'BEFORE',
  AFTER = 'AFTER',
  CHILD = 'CHILD',
}

const initialState: BlockDraggableState = {
  dragging: false,
  isDraggable: true,
  dragShadowVisible: false,
};

export const blockDraggableSlice = createSlice({
  name: 'blockDraggable',
  initialState: initialState,
  reducers: {
    startDrag: (
      state,
      action: PayloadAction<{
        startDraggingPosition: {
          x: number;
          y: number;
        };
        draggingId: string;
        draggingContext: DraggableContext;
      }>
    ) => {
      const { draggingContext, startDraggingPosition, draggingId } = action.payload;

      state.dragging = true;
      state.startDraggingPosition = startDraggingPosition;
      state.draggingId = draggingId;
      state.draggingContext = draggingContext;
    },

    drag: (
      state,
      action: PayloadAction<{
        draggingPosition: {
          x: number;
          y: number;
        };
        insertType?: DragInsertType;
        dropId?: string;
        dropContext?: DraggableContext;
      }>
    ) => {
      const { dropContext, dropId, draggingPosition, insertType } = action.payload;

      state.draggingPosition = draggingPosition;
      state.dropContext = dropContext;
      const moveDistance = Math.sqrt(
        Math.pow(draggingPosition.x - state.startDraggingPosition!.x, 2) +
          Math.pow(draggingPosition.y - state.startDraggingPosition!.y, 2)
      );

      state.dropId = dropId;
      state.insertType = insertType;
      state.dragShadowVisible = moveDistance > DRAG_DISTANCE_THRESHOLD;
    },

    endDrag: (state) => {
      return initialState;
    },
  },
});

export const blockDraggableActions = blockDraggableSlice.actions;
