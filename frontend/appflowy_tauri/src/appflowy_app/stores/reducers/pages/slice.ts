import { ViewIconTypePB, ViewLayoutPB, ViewPB } from '@/services/backend';
import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import isEqual from 'lodash-es/isEqual';
import { ImageType } from '$app/application/document/document.types';
import { Nullable } from 'unsplash-js/dist/helpers/typescript';

export const pageTypeMap = {
  [ViewLayoutPB.Document]: 'document',
  [ViewLayoutPB.Board]: 'board',
  [ViewLayoutPB.Grid]: 'grid',
  [ViewLayoutPB.Calendar]: 'calendar',
};
export interface Page {
  id: string;
  parentId: string;
  name: string;
  layout: ViewLayoutPB;
  icon?: PageIcon;
  cover?: PageCover;
}

export interface PageIcon {
  ty: ViewIconTypePB;
  value: string;
}

export enum CoverType {
  Color = 'CoverType.color',
  Image = 'CoverType.file',
  Asset = 'CoverType.asset',
}
export type PageCover = Nullable<{
  image_type?: ImageType;
  cover_selection_type?: CoverType;
  cover_selection?: string;
}>;

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
  showTrashSnackbar: boolean;
}

export const initialState: PageState = {
  pageMap: {},
  relationMap: {},
  expandedIdMap: getExpandedPageIds().reduce((acc, id) => {
    acc[id] = true;
    return acc;
  }, {} as Record<string, boolean>),
  showTrashSnackbar: false,
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

      if (!isEqual(state.pageMap[page.id], page)) {
        state.pageMap[page.id] = page;
      }
    },

    addPage(
      state,
      action: PayloadAction<{
        page: Page;
        isLast?: boolean;
        prevId?: string;
      }>
    ) {
      const { page, prevId, isLast } = action.payload;

      state.pageMap[page.id] = page;
      state.relationMap[page.id] = [];

      const parentId = page.parentId;

      if (isLast) {
        state.relationMap[parentId]?.push(page.id);
      } else {
        const index = prevId ? state.relationMap[parentId]?.indexOf(prevId) ?? -1 : -1;

        state.relationMap[parentId]?.splice(index + 1, 0, page.id);
      }
    },

    deletePages(state, action: PayloadAction<string[]>) {
      const ids = action.payload;

      ids.forEach((id) => {
        const parentId = state.pageMap[id].parentId;
        const parentChildren = state.relationMap[parentId];

        state.relationMap[parentId] = parentChildren && parentChildren.filter((childId) => childId !== id);
        delete state.relationMap[id];
        delete state.expandedIdMap[id];
        delete state.pageMap[id];
      });
    },

    duplicatePage(
      state,
      action: PayloadAction<{
        id: string;
        newId: string;
      }>
    ) {
      const { id, newId } = action.payload;
      const page = state.pageMap[id];
      const newPage = { ...page, id: newId };

      state.pageMap[newPage.id] = newPage;

      const index = state.relationMap[page.parentId]?.indexOf(id);

      state.relationMap[page.parentId]?.splice(index ?? 0, 0, newId);
    },

    movePage(
      state,
      action: PayloadAction<{
        id: string;
        newParentId: string;
        prevId?: string;
      }>
    ) {
      const { id, newParentId, prevId } = action.payload;
      const parentId = state.pageMap[id].parentId;
      const parentChildren = state.relationMap[parentId];

      const index = parentChildren?.indexOf(id) ?? -1;

      if (index > -1) {
        state.relationMap[parentId]?.splice(index, 1);
      }

      state.pageMap[id].parentId = newParentId;
      const newParentChildren = state.relationMap[newParentId] || [];
      const prevIndex = prevId ? newParentChildren.indexOf(prevId) : -1;

      state.relationMap[newParentId]?.splice(prevIndex + 1, 0, id);
    },

    expandPage(state, action: PayloadAction<string>) {
      const id = action.payload;

      state.expandedIdMap[id] = true;
      const ids = Object.keys(state.expandedIdMap).filter((id) => state.expandedIdMap[id]);

      storeExpandedPageIds(ids);
    },

    collapsePage(state, action: PayloadAction<string>) {
      const id = action.payload;

      state.expandedIdMap[id] = false;
      const ids = Object.keys(state.expandedIdMap).filter((id) => state.expandedIdMap[id]);

      storeExpandedPageIds(ids);
    },

    setTrashSnackbar(state, action: PayloadAction<boolean>) {
      state.showTrashSnackbar = action.payload;
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
