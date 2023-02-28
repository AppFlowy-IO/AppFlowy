import { useAppDispatch, useAppSelector } from '../../../stores/store';
import { foldersActions } from '../../../stores/reducers/folders/slice';
import { WorkspaceBackendService } from '../../../stores/effects/folder/workspace/workspace_bd_svc';
import { useError } from '../../error/Error.hooks';

export const useNewFolder = () => {
  const appDispatch = useAppDispatch();
  const workspace = useAppSelector((state) => state.workspace);
  const workspaceBackendService = new WorkspaceBackendService(workspace.id || '');
  const error = useError();

  const onNewFolder = async () => {
    try {
      const newApp = await workspaceBackendService.createApp({
        name: 'New Folder 1',
      });
      appDispatch(foldersActions.addFolder({ id: newApp.id, title: newApp.name }));
    } catch (e: any) {
      error.showError(e?.message);
    }
  };

  return {
    onNewFolder,
  };
};
