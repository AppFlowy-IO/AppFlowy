import { useAppDispatch, useAppSelector } from '../../../stores/store';
import { foldersActions } from '../../../stores/reducers/folders/slice';
import { WorkspaceBackendService } from '../../../stores/effects/folder/workspace/backend_service';

export const useNewFolder = () => {
  const appDispatch = useAppDispatch();
  const workspace = useAppSelector((state) => state.workspace);
  const workspaceBackendService = new WorkspaceBackendService(workspace.id || '');

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
