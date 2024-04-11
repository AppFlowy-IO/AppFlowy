import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { pagesActions } from '$app_reducers/pages/slice';
import { movePage, setLatestOpenedPage, updatePage } from '$app/application/folder/page.service';
import debounce from 'lodash-es/debounce';
import { currentUserActions } from '$app_reducers/current-user/slice';

export const movePageThunk = createAsyncThunk(
  'pages/movePage',
  async (
    payload: {
      sourceId: string;
      targetId: string;
      insertType: 'before' | 'after' | 'inside';
    },
    thunkAPI
  ) => {
    const { sourceId, targetId, insertType } = payload;
    const { getState, dispatch } = thunkAPI;
    const { pageMap, relationMap } = (getState() as RootState).pages;
    const sourcePage = pageMap[sourceId];
    const targetPage = pageMap[targetId];

    if (!sourcePage || !targetPage) return;
    const sourceParentId = sourcePage.parentId;
    const targetParentId = targetPage.parentId;

    if (!sourceParentId || !targetParentId) return;

    const targetParentChildren = relationMap[targetParentId] || [];
    const targetIndex = targetParentChildren.indexOf(targetId);

    if (targetIndex < 0) return;

    let prevId, parentId;

    if (insertType === 'before') {
      const prevIndex = targetIndex - 1;

      parentId = targetParentId;
      if (prevIndex >= 0) {
        prevId = targetParentChildren[prevIndex];
      }
    } else if (insertType === 'after') {
      prevId = targetId;
      parentId = targetParentId;
    } else {
      const targetChildren = relationMap[targetId] || [];

      parentId = targetId;
      if (targetChildren.length > 0) {
        prevId = targetChildren[targetChildren.length - 1];
      }
    }

    dispatch(pagesActions.movePage({ id: sourceId, newParentId: parentId, prevId }));

    await movePage({
      view_id: sourceId,
      new_parent_id: parentId,
      prev_view_id: prevId,
    });
  }
);

const debounceUpdateName = debounce(updatePage, 1000);

export const updatePageName = createAsyncThunk(
  'pages/updateName',
  async (payload: { id: string; name: string; immediate?: boolean }, thunkAPI) => {
    const { dispatch, getState } = thunkAPI;
    const { pageMap } = (getState() as RootState).pages;
    const { id, name, immediate } = payload;
    const page = pageMap[id];

    if (name === page.name) return;

    dispatch(
      pagesActions.onPageChanged({
        ...page,
        name,
      })
    );

    if (immediate) {
      await updatePage({ id, name });
    } else {
      await debounceUpdateName({
        id,
        name,
      });
    }
  }
);

export const openPage = createAsyncThunk('pages/openPage', async (id: string, thunkAPI) => {
  const { dispatch, getState } = thunkAPI;
  const { pageMap } = (getState() as RootState).pages;

  const page = pageMap[id];

  if (!page) return;

  dispatch(currentUserActions.setLatestView(page));
  await setLatestOpenedPage(id);
});
