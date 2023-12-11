import { ViewIconTypePB, ViewLayoutPB, ViewPB } from '@/services/backend';
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface Page {
  id: string;
  parentId: string;
  name: string;
  layout: ViewLayoutPB;
  icon?: PageIcon;
}

export interface PageIcon {
  ty: ViewIconTypePB;
  value: string;
}

export function parserViewPBToPage(view: ViewPB): Page {
  const icon = view.icon;

  return {
    id: view.id,
    name: view.name,
    parentId: view.parent_view_id,
    layout: view.layout,
    icon: icon
      ? {
          ty: icon.ty,
          value: icon.value,
        }
      : undefined,
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
  expandedIdMap: getExpandedPageIds().reduce((acc, id) => {
    acc[id] = true;
    return acc;
  }, {} as Record<string, boolean>),
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
      const ids = Object.keys(state.expandedIdMap).filter(id => state.expandedIdMap[id]);

      storeExpandedPageIds(ids);
    },

    collapsePage(state, action: PayloadAction<string>) {
      const id = action.payload;

      state.expandedIdMap[id] = false;
      const ids = Object.keys(state.expandedIdMap).filter(id => state.expandedIdMap[id]);

      storeExpandedPageIds(ids);
    },
  },
});

export const pagesActions = pagesSlice.actions;

function storeExpandedPageIds(expandedPageIds: string[]) {
  localStorage.setItem('expandedPageIds', JSON.stringify(expandedPageIds));
}

function getExpandedPageIds(): string[] {
  const expandedPageIds = localStorage.getItem('expandedPageIds');

  return expandedPageIds ? JSON.parse(expandedPageIds) : [];
}