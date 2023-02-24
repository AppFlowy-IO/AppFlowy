import { foldersActions } from '../../stores/reducers/folders/slice';
import { useAppDispatch, useAppSelector } from '../../stores/store';
import { pagesActions } from '../../stores/reducers/pages/slice';
import { workspaceActions } from '../../stores/reducers/workspace/slice';
import { WorkspaceBackendService } from '../../stores/effects/folder/workspace/backend_service';
import { UserBackendService } from '../../stores/effects/user/backend_service';

export const useWorkspace = () => {
  const appDispatch = useAppDispatch();
  const currentUser = useAppSelector((state) => state.currentUser);

  let userBackendService: UserBackendService = new UserBackendService(currentUser.id || '');
  let workspaceBackendService: WorkspaceBackendService;

  const loadWorkspaceItems = async () => {
    try {
      const workspaceSettingPB = await userBackendService.getCurrentWorkspace();

      const workspace = workspaceSettingPB.workspace;
      workspaceBackendService = new WorkspaceBackendService(workspace.id);

      appDispatch(workspaceActions.updateWorkspace({ id: workspace.id, name: workspace.name }));

      appDispatch(foldersActions.clearFolders());
      appDispatch(pagesActions.clearPages());

      const apps = workspace.apps.items;
      for (const app of apps) {
        appDispatch(foldersActions.addFolder({ id: app.id, title: app.name }));

        const views = app.belongings.items;
        for (const view of views) {
          appDispatch(pagesActions.addPage({ folderId: app.id, id: view.id, pageType: view.layout, title: view.name }));
        }
      }
    } catch (e) {
      // create workspace for first start
      const workspace = await userBackendService.createWorkspace({ name: 'New Workspace', desc: '' });
      workspaceBackendService = new WorkspaceBackendService(workspace.id);

      appDispatch(workspaceActions.updateWorkspace({ id: workspace.id, name: workspace.name }));

      appDispatch(foldersActions.clearFolders());
      appDispatch(pagesActions.clearPages());
    }
  };

  return {
    loadWorkspaceItems,
  };
};
