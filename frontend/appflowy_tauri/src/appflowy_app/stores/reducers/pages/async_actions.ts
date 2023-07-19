import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { DragInsertType } from '$app_reducers/block-draggable/slice';
import { PageController } from '$app/stores/effects/workspace/page/page_controller';

export const movePageThunk = createAsyncThunk(
  'pages/movePage',
  async (
    payload: {
      sourceId: string;
      targetId: string;
      insertType: DragInsertType;
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

    if (insertType === DragInsertType.BEFORE) {
      const prevIndex = targetIndex - 1;

      parentId = targetParentId;
      if (prevIndex >= 0) {
        prevId = targetParentChildren[prevIndex];
      }
    } else if (insertType === DragInsertType.AFTER) {
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
