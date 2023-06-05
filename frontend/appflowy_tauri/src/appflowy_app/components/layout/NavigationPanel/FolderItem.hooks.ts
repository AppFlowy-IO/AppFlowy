import { foldersActions, IFolder } from '$app_reducers/folders/slice';
import { useEffect, useState } from 'react';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { IPage, pagesActions } from '$app_reducers/pages/slice';
import { ViewLayoutPB } from '@/services/backend';
import { AppBackendService } from '$app/stores/effects/folder/app/app_bd_svc';
import { WorkspaceBackendService } from '$app/stores/effects/folder/workspace/workspace_bd_svc';

import { AppObserver } from '$app/stores/effects/folder/app/app_observer';
import { useNavigate } from 'react-router-dom';
import { INITIAL_FOLDER_HEIGHT, PAGE_ITEM_HEIGHT } from '../../_shared/constants';

import { DocumentController } from '$app/stores/effects/document/document_controller';

export const useFolderEvents = (folder: IFolder, pages: IPage[]) => {
  const appDispatch = useAppDispatch();
  const workspace = useAppSelector((state) => state.workspace);

  const navigate = useNavigate();

  // Actions
  const [showPages, setShowPages] = useState(false);
  const [showFolderOptions, setShowFolderOptions] = useState(false);
  const [showNewPageOptions, setShowNewPageOptions] = useState(false);
  const [showRenamePopup, setShowRenamePopup] = useState(false);

  // UI configurations
  const [folderHeight, setFolderHeight] = useState(`${INITIAL_FOLDER_HEIGHT}px`);

  // Observers
  const appObserver = new AppObserver(folder.id);

  // Backend services
  const appBackendService = new AppBackendService(folder.id);

  useEffect(() => {
    void appObserver.subscribe({
      onViewsChanged: async () => {
        const result = await appBackendService.getAllViews();
        if (!result.ok) return;
        const views = result.val;
        const updatedPages: IPage[] = views.map((view) => ({
          id: view.id,
          folderId: view.parent_view_id,
          pageType: view.layout,
          title: view.name,
        }));
        appDispatch(pagesActions.didReceivePages({ pages: updatedPages, folderId: folder.id }));
      },
    });
    return () => {
      // Unsubscribe when the component is unmounted.
      void appObserver.unsubscribe();
    };
  }, []);

  useEffect(() => {
    if (showPages) {
      setFolderHeight(`${INITIAL_FOLDER_HEIGHT + pages.length * PAGE_ITEM_HEIGHT}px`);
    }
  }, [pages]);

  const onFolderNameClick = () => {
    if (showPages) {
      setFolderHeight(`${INITIAL_FOLDER_HEIGHT}px`);
    } else {
      setFolderHeight(`${INITIAL_FOLDER_HEIGHT + pages.length * PAGE_ITEM_HEIGHT}px`);
    }
    setShowPages(!showPages);
  };

  const onFolderOptionsClick = () => {
    setShowFolderOptions(!showFolderOptions);
  };

  const onNewPageClick = () => {
    setShowNewPageOptions(!showNewPageOptions);
  };

  const startFolderRename = () => {
    closePopup();
    setShowRenamePopup(true);
  };

  const changeFolderTitle = async (newTitle: string) => {
    await appBackendService.update({ name: newTitle });
    appDispatch(foldersActions.renameFolder({ id: folder.id, newTitle }));
  };

  const closeRenamePopup = () => {
    setShowRenamePopup(false);
  };

  const deleteFolder = async () => {
    closePopup();
    await appBackendService.delete();
    appDispatch(foldersActions.deleteFolder({ id: folder.id }));
  };

  const duplicateFolder = async () => {
    closePopup();
    const workspaceBackendService = new WorkspaceBackendService(workspace.id ?? '');
    const newApp = await workspaceBackendService.createApp({
      name: folder.title,
    });
    appDispatch(foldersActions.addFolder({ id: newApp.id, title: folder.title }));
  };

  const closePopup = () => {
    setShowFolderOptions(false);
    setShowNewPageOptions(false);
  };

  const onAddNewDocumentPage = async () => {
    closePopup();
    const newView = await appBackendService.createView({
      name: 'New Document 1',
      layoutType: ViewLayoutPB.Document,
    });
    try {
      const c = new DocumentController(newView.id);
      await c.create();
      await c.dispose();
      appDispatch(
        pagesActions.addPage({
          folderId: folder.id,
          pageType: ViewLayoutPB.Document,
          title: newView.name,
          id: newView.id,
        })
      );

      setShowPages(true);

      navigate(`/page/document/${newView.id}`);
    } catch (e) {
      console.error(e);
    }
  };

  const onAddNewBoardPage = async () => {
    closePopup();
    const newView = await appBackendService.createView({
      name: 'New Board 1',
      layoutType: ViewLayoutPB.Board,
    });

    setShowPages(true);

    appDispatch(
      pagesActions.addPage({
        folderId: folder.id,
        pageType: ViewLayoutPB.Board,
        title: newView.name,
        id: newView.id,
      })
    );

    navigate(`/page/board/${newView.id}`);
  };

  const onAddNewGridPage = async () => {
    closePopup();
    const newView = await appBackendService.createView({
      name: 'New Grid 1',
      layoutType: ViewLayoutPB.Grid,
    });

    setShowPages(true);

    appDispatch(
      pagesActions.addPage({
        folderId: folder.id,
        pageType: ViewLayoutPB.Grid,
        title: newView.name,
        id: newView.id,
      })
    );

    navigate(`/page/grid/${newView.id}`);
  };

  useEffect(() => {
    appDispatch(foldersActions.setShowPages({ id: folder.id, showPages: showPages }));
  }, [showPages]);

  return {
    showPages,
    onFolderNameClick,
    showFolderOptions,
    onFolderOptionsClick,
    showNewPageOptions,
    onNewPageClick,

    showRenamePopup,
    startFolderRename,
    changeFolderTitle,
    closeRenamePopup,
    deleteFolder,
    duplicateFolder,

    onAddNewDocumentPage,
    onAddNewBoardPage,
    onAddNewGridPage,

    closePopup,
    folderHeight,
  };
};
