import { foldersActions, IFolder } from '../../../stores/reducers/folders/slice';
import { useState } from 'react';
import { useAppDispatch, useAppSelector } from '../../../stores/store';
import { IPage, pagesActions } from '../../../stores/reducers/pages/slice';
import { ViewLayoutTypePB } from '../../../../services/backend';
import { AppBackendService } from '../../../stores/effects/folder/app/backend_service';
import { WorkspaceBackendService } from '../../../stores/effects/folder/workspace/backend_service';
import { useError } from '../../error/Error.hooks';

const initialFolderHeight = 40;
const initialPageHeight = 40;
const animationDuration = 500;

export const useFolderEvents = (folder: IFolder, pages: IPage[]) => {
  const appDispatch = useAppDispatch();

  const [showPages, setShowPages] = useState(false);
  const [showFolderOptions, setShowFolderOptions] = useState(false);
  const [showNewPageOptions, setShowNewPageOptions] = useState(false);
  const [showRenamePopup, setShowRenamePopup] = useState(false);

  const [folderHeight, setFolderHeight] = useState(`${initialFolderHeight}px`);

  const workspace = useAppSelector((state) => state.workspace);

  const appBackendService = new AppBackendService(folder.id);
  const workspaceBackendService = new WorkspaceBackendService(workspace.id || '');
  const error = useError();

  const onFolderNameClick = () => {
    if (showPages) {
      setFolderHeight(`${initialFolderHeight}px`);
    } else {
      setFolderHeight(`${initialFolderHeight + pages.length * initialPageHeight}px`);
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

      appDispatch(
        pagesActions.addPage({
          folderId: folder.id,
          pageType: ViewLayoutTypePB.Board,
          title: newView.name,
          id: newView.id,
        })
      );
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

      appDispatch(
        pagesActions.addPage({
          folderId: folder.id,
          pageType: ViewLayoutTypePB.Grid,
          title: newView.name,
          id: newView.id,
        })
      );
    } catch (e: any) {
      error.showError(e?.message);
    }
  };

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
    animationDuration,
  };
};
