import { foldersActions, IFolder } from '../../../stores/reducers/folders/slice';
import { useState } from 'react';
import { useAppDispatch } from '../../../stores/store';
import { nanoid } from 'nanoid';
import { IPage, pagesActions } from '../../../stores/reducers/pages/slice';
import { UpdateAppPayloadPB, ViewLayoutTypePB } from '../../../../services/backend';
import { FolderEventUpdateApp } from '../../../../services/backend/events/flowy-folder';

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
    await FolderEventUpdateApp(
      UpdateAppPayloadPB.fromObject({
        name: newTitle,
        desc: '',
        app_id: folder.id,
      })
    );
    appDispatch(foldersActions.renameFolder({ id: folder.id, newTitle }));
  };

  const closeRenamePopup = () => {
    setShowRenamePopup(false);
  };

  const deleteFolder = () => {
    closePopup();
    appDispatch(foldersActions.deleteFolder({ id: folder.id }));
  };

  const duplicateFolder = () => {
    closePopup();
    appDispatch(foldersActions.addFolder({ id: nanoid(8), title: folder.title }));
  };

  const closePopup = () => {
    setShowFolderOptions(false);
    setShowNewPageOptions(false);
  };

  const onAddNewDocumentPage = () => {
    closePopup();
    appDispatch(
      pagesActions.addPage({
        folderId: folder.id,
        pageType: ViewLayoutTypePB.Document,
        title: 'New Page 1',
        id: nanoid(6),
      })
    );
  };

  const onAddNewBoardPage = () => {
    closePopup();

    appDispatch(
      pagesActions.addPage({
        folderId: folder.id,
        pageType: ViewLayoutTypePB.Board,
        title: 'New Board 1',
        id: nanoid(6),
      })
    );
  };

  const onAddNewGridPage = () => {
    closePopup();
    appDispatch(
      pagesActions.addPage({ folderId: folder.id, pageType: ViewLayoutTypePB.Grid, title: 'New Grid 1', id: nanoid(6) })
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
