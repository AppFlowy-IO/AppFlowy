import { foldersActions, IFolder } from '../../../stores/reducers/folders/slice';
import { useState } from 'react';
import { useAppDispatch } from '../../../stores/store';
import { nanoid } from 'nanoid';
import { pagesActions } from '../../../stores/reducers/pages/slice';

export const useFolderEvents = (folder: IFolder) => {
  const appDispatch = useAppDispatch();

  const [showPages, setShowPages] = useState(false);
  const [showFolderOptions, setShowFolderOptions] = useState(false);
  const [showNewPageOptions, setShowNewPageOptions] = useState(false);
  const [showRenamePopup, setShowRenamePopup] = useState(false);

  const onFolderNameClick = () => {
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

  const changeFolderTitle = (newTitle: string) => {
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
    appDispatch(pagesActions.addPage({ folderId: folder.id, pageType: 'document', title: 'New Page 1', id: nanoid(6) }));
  };

  const onAddNewBoardPage = () => {
    closePopup();
    appDispatch(pagesActions.addPage({ folderId: folder.id, pageType: 'board', title: 'New Board 1', id: nanoid(6) }));
  };

  const onAddNewGridPage = () => {
    closePopup();
    appDispatch(pagesActions.addPage({ folderId: folder.id, pageType: 'grid', title: 'New Grid 1', id: nanoid(6) }));
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
  };
};
