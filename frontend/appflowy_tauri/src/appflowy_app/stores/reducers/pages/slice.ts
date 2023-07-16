import { ViewLayoutPB, ViewPB } from '@/services/backend';
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface Page {
  id: string;
  parentId: string;
  name: string;
  layout: ViewLayoutPB;
  icon?: string;
  cover?: string;
}

export function parserViewPBToPage(view: ViewPB) {
  return {
    id: view.id,
    name: view.name,
    parentId: view.parent_view_id,
    layout: view.layout,
    cover: view.cover_url,
    icon: view.icon_url,
  };
}

export interface PageState {
  map: Record<string, Page>;
  childPages: Record<string, string[]>;
  expandedPages: Record<string, boolean>;
}

export const initialState: PageState = {
  map: {},
  childPages: {},
  expandedPages: {},
};

export const pagesSlice = createSlice({
  name: 'pages',
  initialState,
  reducers: {
    addChildPages(
      state,
      action: PayloadAction<{
        childPages: Page[];
        id: string;
      }>
    ) {
      const { childPages, id } = action.payload;
      const pageMap: Record<string, Page> = {};

      const children: string[] = [];

      childPages.forEach((page) => {
        pageMap[page.id] = page;
        children.push(page.id);
      });

      state.map = {
        ...state.map,
        ...pageMap,
      };
      state.childPages[id] = children;
    },

    removeChildPages(state, action: PayloadAction<string>) {
      const parentId = action.payload;

      delete state.childPages[parentId];
    },

    expandPage(state, action: PayloadAction<string>) {
      const id = action.payload;

      state.expandedPages[id] = true;
    },

    collapsePage(state, action: PayloadAction<string>) {
      const id = action.payload;

      state.expandedPages[id] = false;
    },
  },
});

export const pagesActions = pagesSlice.actions;
