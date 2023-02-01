import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface IPage {
  id: string;
  title: string;
  folderId: string;
}

const initialState: IPage[] = [
  { id: 'welcome_page', title: 'Welcome', folderId: 'getting_started' },
  { id: 'first_page', title: 'First Page', folderId: 'my_folder' },
  { id: 'second_page', title: 'Second Page', folderId: 'my_folder' },
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
