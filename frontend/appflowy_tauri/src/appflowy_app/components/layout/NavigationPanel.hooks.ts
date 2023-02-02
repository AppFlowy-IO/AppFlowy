import { useAppDispatch, useAppSelector } from '../../store';
import { foldersActions, IFolder } from '../../redux/folders/slice';
import { nanoid } from 'nanoid';
import { IPage, pagesActions } from '../../redux/pages/slice';
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';

export const useNavigationPanelHooks = function () {
  const appDispatch = useAppDispatch();

  const folders = useAppSelector((state) => state.folders);
  const pages = useAppSelector((state) => state.pages);
  const currentUser = useAppSelector((state) => state.currentUser);
  const width = useAppSelector((state) => state.navigationWidth);
  const [isFolderOpen, setIsFolderOpen] = useState<{ [keys: string]: boolean }>({});
  const [detailsPopupOpenId, setDetailsPopupOpenId] = useState<string>('');
  const [addPagePopupOpenId, setAddPagePopupOpenId] = useState<string>('');
  const [renamingFolderId, setRenamingFolderId] = useState<string>('');
  const [renamingPageId, setRenamingPageId] = useState<string>('');

  useEffect(() => {
    let newObj: { [keys: string]: boolean } = { ...isFolderOpen };

    folders.forEach((folder) => {
      if (isFolderOpen[folder.id] !== true) {
        newObj[folder.id] = false;
      }
    });

    setIsFolderOpen(newObj);
  }, [folders]);

  const navigate = useNavigate();

  const setFolderOpen = (id: string, value: boolean) => {
    setIsFolderOpen({ ...isFolderOpen, [id]: value });
  };

  const onBorderMouseDown = () => {
    const onMouseMove = (e: MouseEvent) => {
      console.log(e.movementX, e.movementY);
    };

    const onMouseUp = () => {
      window.removeEventListener('mousemove', onMouseMove);
      window.removeEventListener('mouseup', onMouseUp);
    };

    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);
  };

  const onAddFolder = () => {
    appDispatch(foldersActions.addFolder({ id: nanoid(8), title: 'New Folder 1' }));
  };

  const onFolderChange = (id: string, newTitle: string) => {
    appDispatch(foldersActions.renameFolder({ id, newTitle }));
  };

  const onAddNewDocumentPage = (folderId: string) => {
    setAddPagePopupOpenId('');
    appDispatch(pagesActions.addPage({ folderId, pageType: 'document', title: 'New Page 1', id: nanoid(6) }));
  };

  const onAddNewBoardPage = (folderId: string) => {
    setAddPagePopupOpenId('');
    appDispatch(pagesActions.addPage({ folderId, pageType: 'board', title: 'New Board 1', id: nanoid(6) }));
  };

  const onAddNewGridPage = (folderId: string) => {
    setAddPagePopupOpenId('');
    appDispatch(pagesActions.addPage({ folderId, pageType: 'grid', title: 'New Grid 1', id: nanoid(6) }));
  };

  const onPageChange = (id: string, newTitle: string) => {
    appDispatch(pagesActions.renamePage({ id, newTitle }));
  };

  const onFolderDetailsClick = (folder: IFolder) => {
    setDetailsPopupOpenId(folder.id);
  };

  const onPageDetailsClick = (page: IPage) => {
    setDetailsPopupOpenId(page.id);
  };

  const startFolderRename = (folder: IFolder) => {
    setDetailsPopupOpenId('');
    setRenamingFolderId(folder.id);
  };

  const completeFolderRename = () => {
    setRenamingFolderId('');
  };

  const deleteFolder = (folder: IFolder) => {
    setDetailsPopupOpenId('');
    appDispatch(foldersActions.deleteFolder({ id: folder.id }));
  };

  const duplicateFolder = (folder: IFolder) => {
    setDetailsPopupOpenId('');
    appDispatch(foldersActions.addFolder({ id: nanoid(8), title: folder.title }));
  };

  const startPageRename = (page: IPage) => {
    setDetailsPopupOpenId('');
    setRenamingPageId(page.id);
  };

  const completePageRename = () => {
    setRenamingPageId('');
  };

  const deletePage = (page: IPage) => {
    setDetailsPopupOpenId('');
    appDispatch(pagesActions.deletePage({ id: page.id }));
  };

  const duplicatePage = (page: IPage) => {
    setDetailsPopupOpenId('');
    appDispatch(
      pagesActions.addPage({ id: nanoid(8), pageType: page.pageType, title: page.title, folderId: page.folderId })
    );
  };

  const closePopup = () => {
    setAddPagePopupOpenId('');
    setDetailsPopupOpenId('');
  };

  const onAddNewPageClick = (id: string) => {
    setAddPagePopupOpenId(id);
  };

  return {
    currentUser,
    width,

    folders,
    isFolderOpen,
    setFolderOpen,
    onFolderDetailsClick,
    onAddFolder,
    startFolderRename,
    renamingFolderId,
    onFolderChange,
    completeFolderRename,
    deleteFolder,
    duplicateFolder,

    onAddNewPageClick,

    pages,
    onPageDetailsClick,
    onAddNewDocumentPage,
    onAddNewBoardPage,
    onAddNewGridPage,
    startPageRename,
    renamingPageId,
    onPageChange,
    completePageRename,
    deletePage,
    duplicatePage,

    detailsPopupOpenId,
    addPagePopupOpenId,
    closePopup,

    navigate,
  };
};
