import { foldersActions } from '../../stores/reducers/folders/slice';
import { useAppDispatch, useAppSelector } from '../../stores/store';
import { pagesActions } from '../../stores/reducers/pages/slice';
import { workspaceActions } from '../../stores/reducers/workspace/slice';
import { UserBackendService } from '../../stores/effects/user/user_bd_svc';

export const useWorkspace = () => {
  const currentUser = useAppSelector((state) => state.currentUser);

  const appDispatch = useAppDispatch();

  const userBackendService: UserBackendService = new UserBackendService(currentUser.id || 0);

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

        const views = app.belongings;
        for (const view of views) {
          appDispatch(pagesActions.addPage({ folderId: app.id, id: view.id, pageType: view.layout, title: view.name }));
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
