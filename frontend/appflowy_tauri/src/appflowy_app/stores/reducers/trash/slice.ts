import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { TrashPB } from '@/services/backend';

export interface Trash {
  id: string;
  name: string;
  modifiedTime: number;
  createTime: number;
}

export function trashPBToTrash(trash: TrashPB) {
  return {
    id: trash.id,
    name: trash.name,
    modifiedTime: trash.modified_time,
    createTime: trash.create_time,
  };
}

interface TrashState {
  list: Trash[];
}

const initialState: TrashState = {
  list: [],
};

export const trashSlice = createSlice({
  name: 'trash',
  initialState,
  reducers: {
    initTrash: (state, action: PayloadAction<Trash[]>) => {
      state.list = action.payload;
    },
    onTrashChanged: (state, action: PayloadAction<Trash[]>) => {
      state.list = action.payload;
    },
  },
});

export const trashActions = trashSlice.actions;
