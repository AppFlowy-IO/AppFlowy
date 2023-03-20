import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface IFolder {
  id: string;
  title: string;
  showPages?: boolean;
}

const initialState: IFolder[] = [];

export const foldersSlice = createSlice({
  name: 'folders',
  initialState: initialState,
  reducers: {
    addFolder(state, action: PayloadAction<IFolder>) {
      state.push(action.payload);
    },
    renameFolder(state, action: PayloadAction<{ id: string; newTitle: string }>) {
      return state.map((f) => (f.id === action.payload.id ? { ...f, title: action.payload.newTitle } : f));
    },
    deleteFolder(state, action: PayloadAction<{ id: string }>) {
      return state.filter((f) => f.id !== action.payload.id);
    },
    clearFolders() {
      return [];
    },
    setShowPages(state, action: PayloadAction<{ id: string; showPages: boolean }>) {
      return state.map((f) => (f.id === action.payload.id ? { ...f, showPages: action.payload.showPages } : f));
    },
  },
});

export const foldersActions = foldersSlice.actions;
