import { foldersActions, IFolder } from '../../../stores/reducers/folders/slice';
import { useState } from 'react';
import { useAppDispatch, useAppSelector } from '../../../stores/store';
import { IPage, pagesActions } from '../../../stores/reducers/pages/slice';
import { ViewDataFormatPB, ViewLayoutTypePB } from '../../../../services/backend';
import { AppBackendService } from '../../../stores/effects/folder/app/backend_service';
import { WorkspaceBackendService } from '../../../stores/effects/folder/workspace/backend_service';

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
      dataFormatType: ViewDataFormatPB.NodeFormat,
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
  };

  const onAddNewBoardPage = async () => {
    closePopup();
    const newView = await appBackendService.createView({
      name: 'New Board 1',
      dataFormatType: ViewDataFormatPB.DatabaseFormat,
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
  };

  const onAddNewGridPage = async () => {
    closePopup();
    const newView = await appBackendService.createView({
      name: 'New Grid 1',
      dataFormatType: ViewDataFormatPB.DatabaseFormat,
      layoutType: ViewLayoutTypePB.Grid,
    });

    appDispatch(
      pagesActions.addPage({ folderId: folder.id, pageType: ViewLayoutTypePB.Grid, title: newView.name, id: newView.id })
    );
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
