import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { ViewLayoutPB } from '@/services/backend';

export interface IPage {
  id: string;
  title: string;
  pageType: ViewLayoutPB;
  parentPageId: string;
  showPagesInside: boolean;
}

const initialState: IPage[] = [];

export const pagesSlice = createSlice({
  name: 'pages',
  initialState: initialState,
  reducers: {
    addInsidePages(state, action: PayloadAction<{ insidePages: IPage[]; currentPageId: string }>) {
      return state
        .filter((page) => page.parentPageId !== action.payload.currentPageId)
        .concat(action.payload.insidePages);
    },
    addPage(state, action: PayloadAction<IPage>) {
      state.push(action.payload);
    },
    toggleShowPages(state, action: PayloadAction<{ id: string }>) {
      return state.map<IPage>((page: IPage) =>
        page.id === action.payload.id ? { ...page, showPagesInside: !page.showPagesInside } : page
      );
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
