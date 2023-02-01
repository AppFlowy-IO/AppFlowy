import { useAppDispatch, useAppSelector } from '../../store';
import { foldersActions } from '../../redux/folders/slice';
import { nanoid } from 'nanoid';
import { pagesActions } from '../../redux/pages/slice';
import { useEffect, useState } from 'react';

export const useNavigationPanelHooks = function () {
  const appDispatch = useAppDispatch();

  const folders = useAppSelector((state) => state.folders);
  const pages = useAppSelector((state) => state.pages);
  const currentUser = useAppSelector((state) => state.currentUser);
  const width = useAppSelector((state) => state.navigationWidth);
  const [isFolderOpen, setIsFolderOpen] = useState<{ [keys: string]: boolean }>({});

  useEffect(() => {
    let newObj: { [keys: string]: boolean } = { ...isFolderOpen };

    folders.forEach((folder) => {
      if (isFolderOpen[folder.id] !== true) {
        newObj[folder.id] = false;
      }
    });

    setIsFolderOpen(newObj);
  }, [folders]);

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
    appDispatch(foldersActions.addFolder({ id: nanoid(6), title: 'New Folder 1' }));
  };

  const onFolderChange = (id: string, newTitle: string) => {
    appDispatch(foldersActions.renameFolder({ id, newTitle }));
  };

  const onAddNewPage = (folderId: string) => {
    appDispatch(pagesActions.addPage({ folderId, title: 'New Page 1', id: nanoid(6) }));
  };

  const onPageChange = (id: string, newTitle: string) => {
    appDispatch(pagesActions.renamePage({ id, newTitle }));
  };

  return {
    currentUser,
    width,
    folders,
    isFolderOpen,
    setFolderOpen,
    onAddFolder,
    onFolderChange,
    onAddNewPage,
    pages,
    onPageChange,
  };
};
