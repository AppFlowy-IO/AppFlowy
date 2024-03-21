import { useCallback, useEffect, useMemo } from 'react';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { workspaceActions, WorkspaceItem } from '$app_reducers/workspace/slice';
import { Page, pagesActions, parserViewPBToPage } from '$app_reducers/pages/slice';
import { subscribeNotifications } from '$app/application/notification';
import { FolderNotification, ViewLayoutPB } from '@/services/backend';
import * as workspaceService from '$app/application/folder/workspace.service';
import { createCurrentWorkspaceChildView } from '$app/application/folder/workspace.service';
import { useNavigate } from 'react-router-dom';

export function useLoadWorkspaces() {
  const dispatch = useAppDispatch();
  const { workspaces, currentWorkspaceId } = useAppSelector((state) => state.workspace);

  const currentWorkspace = useMemo(() => {
    return workspaces.find((workspace) => workspace.id === currentWorkspaceId);
  }, [workspaces, currentWorkspaceId]);

  const initializeWorkspaces = useCallback(async () => {
    const workspaces = await workspaceService.getWorkspaces();

    const currentWorkspaceId = await workspaceService.getCurrentWorkspace();

    dispatch(
      workspaceActions.initWorkspaces({
        workspaces,
        currentWorkspaceId,
      })
    );
  }, [dispatch]);

  return {
    workspaces,
    currentWorkspace,
    initializeWorkspaces,
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
        [FolderNotification.DidUpdateWorkspace]: async (changeset) => {
          dispatch(
            workspaceActions.updateWorkspace({
              id: String(changeset.id),
              name: changeset.name,
              icon: changeset.icon_url,
            })
          );
        },
        [FolderNotification.DidUpdateWorkspaceViews]: async (changeset) => {
          const res = changeset.items;

          onChildPagesChanged(res.map(parserViewPBToPage));
        },
      },
      { id }
    );

    return () => void unsubscribePromise.then((unsubscribe) => unsubscribe());
  }, [dispatch, id, onChildPagesChanged]);

  return {
    openWorkspace,
    deleteWorkspace,
  };
}

export function useWorkspaceActions(workspaceId: string) {
  const navigate = useNavigate();

  const newPage = useCallback(async () => {
    const { id } = await createCurrentWorkspaceChildView({
      name: '',
      layout: ViewLayoutPB.Document,
      parent_view_id: workspaceId,
    });

    navigate(`/page/document/${id}`);
  }, [navigate, workspaceId]);

  return {
    newPage,
  };
}
