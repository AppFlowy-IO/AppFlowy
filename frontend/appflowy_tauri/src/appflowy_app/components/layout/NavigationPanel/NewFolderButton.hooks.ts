import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { foldersActions } from '$app_reducers/folders/slice';
import { WorkspaceBackendService } from '$app/stores/effects/folder/workspace/workspace_bd_svc';

export const useNewFolder = () => {
  const appDispatch = useAppDispatch();
  const workspace = useAppSelector((state) => state.workspace);
  const workspaceBackendService = new WorkspaceBackendService(workspace.id ?? '');

  const onNewFolder = async () => {
    const newApp = await workspaceBackendService.createApp({
      name: 'New Folder 1',
    });
    appDispatch(foldersActions.addFolder({ id: newApp.id, title: newApp.name }));
  };

  return {
    onNewFolder,
  };
};
