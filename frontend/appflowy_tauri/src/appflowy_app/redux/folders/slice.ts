import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface IFolder {
  id: string;
  title: string;
}

const initialState: IFolder[] = [
  { id: 'getting_started', title: 'Getting Started' },
  { id: 'my_folder', title: 'My Folder' },
];

export const foldersSlice = createSlice({
  name: 'folders',
  initialState: initialState,
  reducers: {
    addFolder(state, action: PayloadAction<IFolder>) {
      state.push(action.payload);
    },
    renameFolder(state, action: PayloadAction<{ id: string; newTitle: string }>) {
      return state.map((f) => (f.id === action.payload.id ? { id: f.id, title: action.payload.newTitle } : f));
    },
    deleteFolder(state, action: PayloadAction<{ id: string }>) {
      return state.filter((f) => f.id !== action.payload.id);
    },
  },
});

export const foldersActions = foldersSlice.actions;
