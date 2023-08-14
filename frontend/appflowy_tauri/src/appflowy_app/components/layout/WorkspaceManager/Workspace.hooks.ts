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

  const initializeWorkspaces = useCallback(async () => {
    const workspaces = await controller.getWorkspaces();
    const currentWorkspace = await controller.getCurrentWorkspace();

    dispatch(
      workspaceActions.initWorkspaces({
        workspaces,
        currentWorkspace,
      })
    );
  }, [controller, dispatch]);

  const subscribeToWorkspaces = useCallback(async () => {
    await controller.subscribe({
      onWorkspacesChanged,
    });
  }, [controller, onWorkspacesChanged]);

  useEffect(() => {
    void (async () => {
      await initializeWorkspaces();
      await subscribeToWorkspaces();
    })();

    return () => {
      controller.dispose();
    };
  }, [controller, initializeWorkspaces, subscribeToWorkspaces]);

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

  const initializeWorkspace = useCallback(async () => {
    const childPages = await controller.getChildPages();
    dispatch(
      pagesActions.addChildPages({
        id,
        childPages,
      })
    );
  }, [controller, dispatch, id]);

  const subscribeToWorkspace = useCallback(async () => {
    await controller.subscribe({
      onChildPagesChanged,
    });
  }, [controller, onChildPagesChanged]);

  useEffect(() => {
    void (async () => {
      await initializeWorkspace();
      await subscribeToWorkspace();
    })();

    return () => {
      controller.dispose();
    };
  }, [controller, initializeWorkspace, subscribeToWorkspace]);

  return {
    openWorkspace,
    controller,
    deleteWorkspace,
  };
}
