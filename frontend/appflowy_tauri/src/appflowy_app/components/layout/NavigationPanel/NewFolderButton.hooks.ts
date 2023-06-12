import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { WorkspaceBackendService } from '$app/stores/effects/folder/workspace/workspace_bd_svc';
import { ViewLayoutPB } from '@/services/backend';
import { pagesActions } from '$app_reducers/pages/slice';

export const useNewFolder = () => {
  const appDispatch = useAppDispatch();
  const workspace = useAppSelector((state) => state.workspace);
  const workspaceBackendService = new WorkspaceBackendService(workspace.id ?? '');

  const onNewFolder = async () => {
    // should show options for new page type
    const result = await workspaceBackendService.createView({
      parentViewId: workspace.id,
      layoutType: ViewLayoutPB.Document,
      desc: '',
      name: 'New Folder 1',
    });
    if (result.ok) {
      const newApp = result.val;
      appDispatch(
        pagesActions.addPage({
          parentPageId: workspace.id ?? '',
          id: newApp.id,
          title: newApp.name,
          showPagesInside: false,
          pageType: ViewLayoutPB.Document,
        })
      );
    }
  };

  return {
    onNewFolder,
  };
};
