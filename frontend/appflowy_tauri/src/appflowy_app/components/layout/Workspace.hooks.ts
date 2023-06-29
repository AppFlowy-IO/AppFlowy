import { foldersActions } from '$app_reducers/folders/slice';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { IPage, pagesActions } from '$app_reducers/pages/slice';
import { workspaceActions } from '$app_reducers/workspace/slice';
import { UserBackendService } from '$app/stores/effects/user/user_bd_svc';
import { useEffect, useState } from 'react';
import { WorkspaceBackendService } from '$app/stores/effects/folder/workspace/workspace_bd_svc';

export const useWorkspace = () => {
  const currentUser = useAppSelector((state) => state.currentUser);
  const appDispatch = useAppDispatch();

  const [userService, setUserService] = useState<UserBackendService | null>(null);
  const [workspaceService, setWorkspaceService] = useState<WorkspaceBackendService | null>(null);
  const [isReady, setIsReady] = useState(false);

  useEffect(() => {
    if (currentUser.id) {
      setUserService(new UserBackendService(currentUser.id));
    }
  }, [currentUser]);

  useEffect(() => {
    if (!userService) return;

    void (async () => {
      try {
        const workspaceSettingPB = await userService.getCurrentWorkspace();
        const workspace = workspaceSettingPB.workspace;
        appDispatch(workspaceActions.updateWorkspace({ id: workspace.id, name: workspace.name }));
        appDispatch(foldersActions.clearFolders());
        appDispatch(pagesActions.clearPages());

        setWorkspaceService(new WorkspaceBackendService(workspace.id));
      } catch (e1) {
        // create workspace for first start
        const workspace = await userService.createWorkspace({ name: 'New Workspace', desc: '' });
        appDispatch(workspaceActions.updateWorkspace({ id: workspace.id, name: workspace.name }));

        appDispatch(foldersActions.clearFolders());
        appDispatch(pagesActions.clearPages());
      }
    })();
  }, [userService]);

  useEffect(() => {
    if (!workspaceService) return;
    void (async () => {
      const rootViews = await workspaceService.getAllViews();
      if (rootViews.ok) {
        appDispatch(
          pagesActions.addInsidePages({
            currentPageId: workspaceService.workspaceId,
            insidePages: rootViews.val.map<IPage>((v) => ({
              id: v.id,
              title: v.name,
              pageType: v.layout,
              showPagesInside: false,
              parentPageId: workspaceService.workspaceId,
            })),
          })
        );
        setIsReady(true);
      }
    })();
  }, [workspaceService]);

  return {};
};
