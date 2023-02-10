import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export type PageType = 'document' | 'grid' | 'board';

export interface IPage {
  id: string;
  title: string;
  pageType: PageType;
  folderId: string;
}

const initialState: IPage[] = [
  { id: 'welcome_page', title: 'Welcome', pageType: 'document', folderId: 'getting_started' },
  { id: 'first_page', title: 'First Page', pageType: 'document', folderId: 'my_folder' },
  { id: 'second_page', title: 'Second Page', pageType: 'document', folderId: 'my_folder' },
];

export const pagesSlice = createSlice({
  name: 'pages',
  initialState: initialState,
  reducers: {
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
  },
});

export const pagesActions = pagesSlice.actions;
