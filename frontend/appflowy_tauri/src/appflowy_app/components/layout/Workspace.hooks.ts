import {
  CreateWorkspacePayloadPB,
  FolderEventCreateWorkspace,
  FolderEventReadCurrentWorkspace,
} from '../../../services/backend/events/flowy-folder';
import { foldersActions } from '../../stores/reducers/folders/slice';
import { useAppDispatch } from '../../stores/store';
import { pagesActions } from '../../stores/reducers/pages/slice';
import { workspaceActions } from '../../stores/reducers/workspace/slice';
import { SignInPayloadPB, UserEventSignIn } from '../../../services/backend/events/flowy-user';
import { nanoid } from 'nanoid';

export const useWorkspace = () => {
  const appDispatch = useAppDispatch();

  const loadWorkspaceItems = async () => {
    const readCurrentWorkspaceResult = await FolderEventReadCurrentWorkspace();
    if (readCurrentWorkspaceResult.ok) {
      const pb = readCurrentWorkspaceResult.val;
      const workspace = pb.workspace;
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
    } else {
      // create workspace for first start
      await UserEventSignIn(
        SignInPayloadPB.fromObject({
          email: nanoid(4) + '@gmail.com',
          password: 'A!@123abc',
          name: 'abc',
        })
      );
      const createWorkspaceResult = await FolderEventCreateWorkspace(
        CreateWorkspacePayloadPB.fromObject({
          name: 'New Workspace',
        })
      );
      if (createWorkspaceResult.ok) {
        const workspace = createWorkspaceResult.val;
        appDispatch(workspaceActions.updateWorkspace({ id: workspace.id, name: workspace.name }));

        appDispatch(foldersActions.clearFolders());
        appDispatch(pagesActions.clearPages());
      }
    }
  };

  return {
    loadWorkspaceItems,
  };
};
