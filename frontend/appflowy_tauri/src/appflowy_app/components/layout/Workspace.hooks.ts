import { foldersActions } from '$app_reducers/folders/slice';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { pagesActions } from '$app_reducers/pages/slice';
import { workspaceActions } from '$app_reducers/workspace/slice';
import { UserBackendService } from '$app/stores/effects/user/user_bd_svc';
import { AppBackendService } from '$app/stores/effects/folder/app/app_bd_svc';
import { Log } from '$app/utils/log';

export const useWorkspace = () => {
  const currentUser = useAppSelector((state) => state.currentUser);

  const appDispatch = useAppDispatch();

  const userBackendService: UserBackendService = new UserBackendService(currentUser.id ?? 0);

  const loadWorkspaceItems = async () => {
    try {
      const workspaceSettingPB = await userBackendService.getCurrentWorkspace();
      const workspace = workspaceSettingPB.workspace;
      appDispatch(workspaceActions.updateWorkspace({ id: workspace.id, name: workspace.name }));
      appDispatch(foldersActions.clearFolders());
      appDispatch(pagesActions.clearPages());

      const apps = workspace.views;
      for (const app of apps) {
        appDispatch(foldersActions.addFolder({ id: app.id, title: app.name }));
        const service = new AppBackendService(app.id);
        const result = await service.getAllViews();
        if (result.ok) {
          for (const view of result.val) {
            appDispatch(
              pagesActions.addPage({ folderId: app.id, id: view.id, pageType: view.layout, title: view.name })
            );
          }
        } else {
          Log.error('Failed to get views, folderId: ' + app.id);
        }
      }
    } catch (e1) {
      // create workspace for first start
      const workspace = await userBackendService.createWorkspace({ name: 'New Workspace', desc: '' });
      appDispatch(workspaceActions.updateWorkspace({ id: workspace.id, name: workspace.name }));

      appDispatch(foldersActions.clearFolders());
      appDispatch(pagesActions.clearPages());
    }
  };

  return {
    loadWorkspaceItems,
  };
};
