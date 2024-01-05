import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { PageController } from '$app/stores/effects/workspace/page/page_controller';
import { PageIcon, pagesActions } from '$app_reducers/pages/slice';

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
    const { getState } = thunkAPI;
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

    const controller = new PageController(sourceId);

    await controller.movePage({ parentId, prevId });
  }
);

export const updatePageName = createAsyncThunk(
  'pages/updateName',
  async (payload: { id: string; name: string }, thunkAPI) => {
    const controller = new PageController(payload.id);
    const { dispatch, getState } = thunkAPI;
    const { pageMap } = (getState() as RootState).pages;
    const { id, name } = payload;
    const page = pageMap[id];

    if (name === page.name) return;

    dispatch(
      pagesActions.onPageChanged({
        ...page,
        name,
      })
    );
    await controller.updatePage({
      id: payload.id,
      name: payload.name,
    });
  }
);

export const updatePageIcon = createAsyncThunk('pages/updateIcon', async (payload: { id: string; icon?: PageIcon }) => {
  const controller = new PageController(payload.id);

  await controller.updatePageIcon(payload.icon);
});
