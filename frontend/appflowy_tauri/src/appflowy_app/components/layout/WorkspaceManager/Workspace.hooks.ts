import { useCallback, useEffect, useMemo } from 'react';
import { WorkspaceController } from '$app/stores/effects/workspace/workspace_controller';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { workspaceActions, WorkspaceItem } from '$app_reducers/workspace/slice';
import { WorkspaceManagerController } from '$app/stores/effects/workspace/workspace_manager_controller';
import { Page, pagesActions } from '$app_reducers/pages/slice';

export function useLoadWorkspaces() {
  const dispatch = useAppDispatch();
  const { workspaces, currentWorkspace } = useAppSelector((state) => state.workspace);

  const onWorkspacesChanged = useCallback(
    (data: { workspaces: WorkspaceItem[]; currentWorkspace: WorkspaceItem }) => {
      dispatch(workspaceActions.onWorkspacesChanged(data));
    },
    [dispatch]
  );

  const controller = useMemo(() => {
    return new WorkspaceManagerController();
  }, []);

  useEffect(() => {
    void (async () => {
      const workspaces = await controller.getWorkspaces();
      const currentWorkspace = await controller.getCurrentWorkspace();

      await controller.subscribe({
        onWorkspacesChanged,
      });
      dispatch(
        workspaceActions.initWorkspaces({
          workspaces,
          currentWorkspace,
        })
      );
    })();

    return () => {
      controller.dispose();
    };
  }, [controller, dispatch, onWorkspacesChanged]);

  return {
    workspaces,
    currentWorkspace,
  };
}

export function useLoadWorkspace(workspace: WorkspaceItem) {
  const { id } = workspace;
  const dispatch = useAppDispatch();

  const controller = useMemo(() => {
    return new WorkspaceController(id);
  }, [id]);

  const onWorkspaceChanged = useCallback(
    (data: WorkspaceItem) => {
      dispatch(workspaceActions.onWorkspaceChanged(data));
    },
    [dispatch]
  );

  const onWorkspaceDeleted = useCallback(() => {
    dispatch(workspaceActions.onWorkspaceDeleted(id));
  }, [dispatch, id]);

  const openWorkspace = useCallback(async () => {
    await controller.open();
  }, [controller]);

  const deleteWorkspace = useCallback(async () => {
    await controller.delete();
  }, [controller]);

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

  useEffect(() => {
    void (async () => {
      const childPages = await controller.getChildPages();

      dispatch(
        pagesActions.addChildPages({
          id,
          childPages,
        })
      );
      await controller.subscribe({
        onWorkspaceChanged,
        onWorkspaceDeleted,
        onChildPagesChanged,
      });
    })();

    return () => {
      controller.dispose();
    };
  }, [controller, dispatch, id, onChildPagesChanged, onWorkspaceChanged, onWorkspaceDeleted]);

  return {
    openWorkspace,
    controller,
    deleteWorkspace,
  };
}
