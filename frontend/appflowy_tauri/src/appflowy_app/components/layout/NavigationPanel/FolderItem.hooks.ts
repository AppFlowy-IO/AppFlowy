import { foldersActions, IFolder } from '../../../stores/reducers/folders/slice';
import { useEffect, useState } from 'react';
import { useAppDispatch, useAppSelector } from '../../../stores/store';
import { IPage, pagesActions } from '../../../stores/reducers/pages/slice';
import { AppPB, ViewLayoutTypePB } from '@/services/backend';
import { AppBackendService } from '../../../stores/effects/folder/app/app_bd_svc';
import { WorkspaceBackendService } from '../../../stores/effects/folder/workspace/workspace_bd_svc';
import { useError } from '../../error/Error.hooks';
import { AppObserver } from '../../../stores/effects/folder/app/app_observer';
import { useNavigate } from 'react-router-dom';
import { INITIAL_FOLDER_HEIGHT, PAGE_ITEM_HEIGHT } from '../../_shared/constants';

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
  const workspaceBackendService = new WorkspaceBackendService(workspace.id || '');

  // Error
  const error = useError();

  useEffect(() => {
    void appObserver.subscribe({
      onAppChanged: (change) => {
        if (change.ok) {
          const app: AppPB = change.val;
          const updatedPages: IPage[] = app.belongings.items.map((view) => ({
            id: view.id,
            folderId: view.app_id,
            pageType: view.layout,
            title: view.name,
          }));
          appDispatch(pagesActions.didReceivePages(updatedPages));
        }
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
    try {
      await appBackendService.update({ name: newTitle });
      appDispatch(foldersActions.renameFolder({ id: folder.id, newTitle }));
    } catch (e: any) {
      error.showError(e?.message);
    }
  };

  const closeRenamePopup = () => {
    setShowRenamePopup(false);
  };

  const deleteFolder = async () => {
    closePopup();
    try {
      await appBackendService.delete();
      appDispatch(foldersActions.deleteFolder({ id: folder.id }));
    } catch (e: any) {
      error.showError(e?.message);
    }
  };

  const duplicateFolder = async () => {
    closePopup();
    try {
      const newApp = await workspaceBackendService.createApp({
        name: folder.title,
      });
      appDispatch(foldersActions.addFolder({ id: newApp.id, title: folder.title }));
    } catch (e: any) {
      error.showError(e?.message);
    }
  };

  const closePopup = () => {
    setShowFolderOptions(false);
    setShowNewPageOptions(false);
  };

  const onAddNewDocumentPage = async () => {
    closePopup();
    try {
      const newView = await appBackendService.createView({
        name: 'New Document 1',
        layoutType: ViewLayoutTypePB.Document,
      });

      appDispatch(
        pagesActions.addPage({
          folderId: folder.id,
          pageType: ViewLayoutTypePB.Document,
          title: newView.name,
          id: newView.id,
        })
      );

      setShowPages(true);

      navigate(`/page/document/${newView.id}`);
    } catch (e: any) {
      error.showError(e?.message);
    }
  };

  const onAddNewBoardPage = async () => {
    closePopup();
    try {
      const newView = await appBackendService.createView({
        name: 'New Board 1',
        layoutType: ViewLayoutTypePB.Board,
      });

      setShowPages(true);

      appDispatch(
        pagesActions.addPage({
          folderId: folder.id,
          pageType: ViewLayoutTypePB.Board,
          title: newView.name,
          id: newView.id,
        })
      );

      navigate(`/page/board/${newView.id}`);
    } catch (e: any) {
      error.showError(e?.message);
    }
  };

  const onAddNewGridPage = async () => {
    closePopup();
    try {
      const newView = await appBackendService.createView({
        name: 'New Grid 1',
        layoutType: ViewLayoutTypePB.Grid,
      });

      setShowPages(true);

      appDispatch(
        pagesActions.addPage({
          folderId: folder.id,
          pageType: ViewLayoutTypePB.Grid,
          title: newView.name,
          id: newView.id,
        })
      );

      navigate(`/page/grid/${newView.id}`);
    } catch (e: any) {
      error.showError(e?.message);
    }
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
