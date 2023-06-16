import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { WorkspaceBackendService } from '$app/stores/effects/folder/workspace/workspace_bd_svc';
import { ViewLayoutPB } from '@/services/backend';
import { pagesActions } from '$app_reducers/pages/slice';
import { useNavigate } from 'react-router-dom';

export const useNewRootView = () => {
  const appDispatch = useAppDispatch();
  const workspace = useAppSelector((state) => state.workspace);
  const navigate = useNavigate();

  const onNewRootView = async () => {
    if (!workspace.id) return;
    const workspaceBackendService = new WorkspaceBackendService(workspace.id);

    // in future should show options for new page type
    const defaultType = ViewLayoutPB.Document;
    const defaultName = 'Document Page 1';
    const defaultRoute = 'document';

    const result = await workspaceBackendService.createView({
      parentViewId: workspace.id,
      layoutType: defaultType,
      name: defaultName,
    });

    if (result.ok) {
      const newView = result.val;
      appDispatch(
        pagesActions.addPage({
          parentPageId: workspace.id,
          id: newView.id,
          title: newView.name,
          showPagesInside: false,
          pageType: defaultType,
        })
      );
      navigate(`/page/${defaultRoute}/${newView.id}`);
    }
  };

  return {
    onNewRootView,
  };
};
