import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { ViewLayoutTypePB } from '@/services/backend';

export interface IPage {
  id: string;
  title: string;
  pageType: ViewLayoutTypePB;
  folderId: string;
}

const initialState: IPage[] = [];

export const pagesSlice = createSlice({
  name: 'pages',
  initialState: initialState,
  reducers: {
    didReceivePages(state, action: PayloadAction<IPage[]>) {
      return action.payload;
    },
    addPage(state, action: PayloadAction<IPage>) {
      state.push(action.payload);
    },
    renamePage(state, action: PayloadAction<{ id: string; newTitle: string }>) {
      return state.map<IPage>((page: IPage) =>
        page.id === action.payload.id ? { ...page, title: action.payload.newTitle } : page
      );
    },
    deletePage(state, action: PayloadAction<{ id: string }>) {
      return state.filter((page) => page.id !== action.payload.id);
    },
    clearPages() {
      return [];
    },
  },
});

export const pagesActions = pagesSlice.actions;
