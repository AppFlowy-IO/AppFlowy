import { useAppDispatch, useAppSelector } from '../../../stores/store';
import { foldersActions } from '../../../stores/reducers/folders/slice';
import { nanoid } from 'nanoid';
import { CreateAppPayloadPB, FolderEventCreateApp } from '../../../../services/backend/events/flowy-folder';
import { workspaceSlice } from '../../../stores/reducers/workspace/slice';

export const useNewFolder = () => {
  const appDispatch = useAppDispatch();
  const workspace = useAppSelector((state) => state.workspace);

  const onNewFolder = async () => {
    const createAppResult = await FolderEventCreateApp(
      CreateAppPayloadPB.fromObject({
        workspace_id: workspace.id,
        name: 'New Folder 1',
        desc: '',
      })
    );
    if (createAppResult.ok) {
      const pb = createAppResult.val;

      appDispatch(foldersActions.addFolder({ id: pb.id, title: pb.name }));
    } else {
      throw new Error('create app error');
    }
  };

  return {
    onNewFolder,
  };
};
