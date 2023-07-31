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
  pageMap: Record<string, Page>;
  relationMap: Record<string, string[] | undefined>;
  expandedIdMap: Record<string, boolean>;
}

export const initialState: PageState = {
  pageMap: {},
  relationMap: {},
  expandedIdMap: {},
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

      state.pageMap = {
        ...state.pageMap,
        ...pageMap,
      };
      state.relationMap[id] = children;
    },

    onPageChanged(state, action: PayloadAction<Page>) {
      const page = action.payload;

      state.pageMap[page.id] = page;
    },

    removeChildPages(state, action: PayloadAction<string>) {
      const parentId = action.payload;

      delete state.relationMap[parentId];
    },

    expandPage(state, action: PayloadAction<string>) {
      const id = action.payload;

      state.expandedIdMap[id] = true;
    },

    collapsePage(state, action: PayloadAction<string>) {
      const id = action.payload;

      state.expandedIdMap[id] = false;
    },
  },
});

export const pagesActions = pagesSlice.actions;
