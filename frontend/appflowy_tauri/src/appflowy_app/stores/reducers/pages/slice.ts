import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { ViewLayoutTypePB } from '../../../../services/backend';

export interface IPage {
  id: string;
  title: string;
  pageType: ViewLayoutTypePB;
  folderId: string;
  offsetTop?: number;
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
    setOffsetTop(state, action: PayloadAction<{ id: string; offset: number }>) {
      return state.map((page) => (page.id === action.payload.id ? { ...page, offsetTop: action.payload.offset } : page));
    },
  },
});

export const pagesActions = pagesSlice.actions;
