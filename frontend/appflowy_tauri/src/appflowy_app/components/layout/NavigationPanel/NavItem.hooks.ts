import { useEffect, useState } from 'react';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { IPage, pagesActions } from '$app_reducers/pages/slice';
import { ViewLayoutPB } from '@/services/backend';
import { WorkspaceBackendService } from '$app/stores/effects/folder/workspace/workspace_bd_svc';

import { useLocation, useNavigate } from 'react-router-dom';
import { INITIAL_FOLDER_HEIGHT, PAGE_ITEM_HEIGHT } from '../../_shared/constants';

import { DocumentController } from '$app/stores/effects/document/document_controller';
import { ViewBackendService } from '$app/stores/effects/folder/view/view_bd_svc';
import { ViewObserver } from '$app/stores/effects/folder/view/view_observer';

export const useNavItem = (page: IPage) => {
  const appDispatch = useAppDispatch();
  const workspace = useAppSelector((state) => state.workspace);
  const currentLocation = useLocation();
  const [activePageId, setActivePageId] = useState<string>('');
  const pages = useAppSelector((state) => state.pages);

  const navigate = useNavigate();

  // Actions
  const [showPageOptions, setShowPageOptions] = useState(false);
  const [showNewPageOptions, setShowNewPageOptions] = useState(false);
  const [showRenamePopup, setShowRenamePopup] = useState(false);

  // UI configurations
  const [folderHeight, setFolderHeight] = useState(`${INITIAL_FOLDER_HEIGHT}px`);

  // backend
  const service = new ViewBackendService(page.id);
  const observer = new ViewObserver(page.id);

  const loadInsidePages = async () => {
    const result = await service.getChildViews();
    if (!result.ok) return;
    const views = result.val;
    const updatedPages: IPage[] = views.map<IPage>((view) => ({
      parentPageId: page.id,
      id: view.id,
      pageType: view.layout,
      title: view.name,
      showPagesInside: false,
    }));
    appDispatch(pagesActions.addInsidePages({ currentPageId: page.id, insidePages: updatedPages }));
  };

  useEffect(() => {
    void loadInsidePages();
    void observer.subscribe({
      onChildViewsChanged: () => {
        console.log('onChildViewsChanged: ', page.title);
        void loadInsidePages();
      },
    });
    return () => {
      // Unsubscribe when the component is unmounted.
      void observer.unsubscribe();
    };
  }, []);

  useEffect(() => {
    const { pathname } = currentLocation;
    const parts = pathname.split('/');
    const pageId = parts[parts.length - 1];
    setActivePageId(pageId);
  }, [currentLocation]);

  useEffect(() => {
    if (page.showPagesInside) {
      setFolderHeight(
        `${INITIAL_FOLDER_HEIGHT + pages.filter((p) => p.parentPageId === page.id).length * PAGE_ITEM_HEIGHT}px`
      );
    } else {
      setFolderHeight(`${INITIAL_FOLDER_HEIGHT}px`);
    }
  }, [page, pages]);

  const viewBackendService: ViewBackendService = new ViewBackendService(page.id);

  const onUnfoldClick = () => {
    appDispatch(pagesActions.toggleShowPages({ id: page.id }));
  };

  const onPageOptionsClick = () => {
    setShowPageOptions(!showPageOptions);
  };

  const startPageRename = () => {
    setShowRenamePopup(true);
    closePopup();
  };

  const onNewPageClick = () => {
    setShowNewPageOptions(!showNewPageOptions);
  };

  const changePageTitle = async (newTitle: string) => {
    await viewBackendService.update({ name: newTitle });
    appDispatch(pagesActions.renamePage({ id: page.id, newTitle }));
  };

  const closeRenamePopup = () => {
    setShowRenamePopup(false);
  };

  const deletePage = async () => {
    closePopup();
    await viewBackendService.delete();
    appDispatch(pagesActions.deletePage({ id: page.id }));
  };

  const duplicatePage = async () => {
    closePopup();
    await viewBackendService.duplicate();
  };

  const closePopup = () => {
    setShowPageOptions(false);
    setShowNewPageOptions(false);
  };

  const onPageClick = (page: IPage) => {
    const pageTypeRoute = (() => {
      switch (page.pageType) {
        case ViewLayoutPB.Document:
          return 'document';
        case ViewLayoutPB.Grid:
          return 'grid';
        case ViewLayoutPB.Board:
          return 'board';
        default:
          return 'document';
      }
    })();

    navigate(`/page/${pageTypeRoute}/${page.id}`);
  };

  const onAddNewDocumentPage = async () => {
    closePopup();
    if (!workspace?.id) return;
    const workspaceService = new WorkspaceBackendService(workspace.id);
    const newViewResult = await workspaceService.createView({
      name: 'New Document 1',
      layoutType: ViewLayoutPB.Document,
      parentViewId: page.id,
    });
    if (newViewResult.ok) {
      try {
        const newView = newViewResult.val;
        const c = new DocumentController(newView.id);
        await c.create();
        await c.dispose();
        appDispatch(
          pagesActions.addPage({
            parentPageId: page.id,
            pageType: ViewLayoutPB.Document,
            title: newView.name,
            id: newView.id,
            showPagesInside: false,
          })
        );
        appDispatch(pagesActions.toggleShowPages({ id: page.id }));

        navigate(`/page/document/${newView.id}`);
      } catch (e) {
        console.error(e);
      }
    }
  };

  const onAddNewBoardPage = async () => {
    closePopup();
    if (!workspace?.id) return;
    const workspaceService = new WorkspaceBackendService(workspace.id);
    const newViewResult = await workspaceService.createView({
      name: 'New Board 1',
      layoutType: ViewLayoutPB.Board,
      parentViewId: page.id,
    });

    if (newViewResult.ok) {
      const newView = newViewResult.val;
      appDispatch(pagesActions.toggleShowPages({ id: page.id }));

      appDispatch(
        pagesActions.addPage({
          parentPageId: page.id,
          pageType: ViewLayoutPB.Board,
          title: newView.name,
          id: newView.id,
          showPagesInside: false,
        })
      );

      navigate(`/page/board/${newView.id}`);
    }
  };

  const onAddNewGridPage = async () => {
    closePopup();
    if (!workspace?.id) return;
    const workspaceService = new WorkspaceBackendService(workspace.id);
    const newViewResult = await workspaceService.createView({
      name: 'New Grid 1',
      layoutType: ViewLayoutPB.Grid,
      parentViewId: page.id,
    });

    if (newViewResult.ok) {
      const newView = newViewResult.val;
      appDispatch(pagesActions.toggleShowPages({ id: page.id }));

      appDispatch(
        pagesActions.addPage({
          parentPageId: page.id,
          pageType: ViewLayoutPB.Grid,
          title: newView.name,
          id: newView.id,
          showPagesInside: false,
        })
      );

      navigate(`/page/grid/${newView.id}`);
    }
  };

  return {
    onUnfoldClick,
    onNewPageClick,
    onPageOptionsClick,
    startPageRename,

    changePageTitle,
    closeRenamePopup,
    closePopup,

    showNewPageOptions,
    showPageOptions,
    showRenamePopup,

    deletePage,
    duplicatePage,

    onPageClick,

    onAddNewDocumentPage,
    onAddNewBoardPage,
    onAddNewGridPage,

    folderHeight,
    activePageId,
  };
};
