import { useCallback, useEffect } from 'react';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { workspaceActions, WorkspaceItem } from '$app_reducers/workspace/slice';
import { Page, pagesActions, parserViewPBToPage } from '$app_reducers/pages/slice';
import { subscribeNotifications } from '$app/application/notification';
import { FolderNotification } from '@/services/backend';
import * as workspaceService from '$app/application/folder/workspace.service';

export function useLoadWorkspaces() {
  const dispatch = useAppDispatch();
  const { workspaces, currentWorkspace } = useAppSelector((state) => state.workspace);

  const initializeWorkspaces = useCallback(async () => {
    const workspaces = await workspaceService.getWorkspaces();
    const currentWorkspace = await workspaceService.getCurrentWorkspace();

    dispatch(
      workspaceActions.initWorkspaces({
        workspaces,
        currentWorkspace,
      })
    );
  }, [dispatch]);

  useEffect(() => {
    void (async () => {
      await initializeWorkspaces();
    })();
  }, [initializeWorkspaces]);

  return {
    workspaces,
    currentWorkspace,
  };
}

export function useLoadWorkspace(workspace: WorkspaceItem) {
  const { id } = workspace;
  const dispatch = useAppDispatch();

  const openWorkspace = useCallback(async () => {
    await workspaceService.openWorkspace(id);
  }, [id]);

  const deleteWorkspace = useCallback(async () => {
    await workspaceService.deleteWorkspace(id);
  }, [id]);

  const onChildPagesChanged = useCallback(
    (childPages: Page[]) => {
      dispatch(
        pagesActions.addChildPages({
          id,
          childPages,
        })
      );
    },
    [dispatch, id]
  );

  const initializeWorkspace = useCallback(async () => {
    const childPages = await workspaceService.getWorkspaceChildViews(id);

    dispatch(
      pagesActions.addChildPages({
        id,
        childPages,
      })
    );
  }, [dispatch, id]);

  useEffect(() => {
    void (async () => {
      await initializeWorkspace();
    })();
  }, [initializeWorkspace]);

  useEffect(() => {
    const unsubscribePromise = subscribeNotifications(
      {
        [FolderNotification.DidUpdateWorkspaceViews]: async (changeset) => {
          const res = changeset.items;

          onChildPagesChanged(res.map(parserViewPBToPage));
        },
      },
      { id }
    );

    return () => void unsubscribePromise.then((unsubscribe) => unsubscribe());
  }, [id, onChildPagesChanged]);

  return {
    openWorkspace,
    deleteWorkspace,
  };
}
