import { IPage, pagesActions } from '../../../stores/reducers/pages/slice';
import { useAppDispatch } from '../../../stores/store';
import { useState } from 'react';
import { nanoid } from 'nanoid';

export const usePageEvents = (page: IPage) => {
  const appDispatch = useAppDispatch();
  const [showPageOptions, setShowPageOptions] = useState(false);
  const [showRenamePopup, setShowRenamePopup] = useState(false);

  const onPageOptionsClick = () => {
    setShowPageOptions(!showPageOptions);
  };

  const startPageRename = () => {
    setShowRenamePopup(true);
    closePopup();
  };

  const changePageTitle = (newTitle: string) => {
    appDispatch(pagesActions.renamePage({ id: page.id, newTitle }));
  };

  const deletePage = () => {
    closePopup();
    appDispatch(pagesActions.deletePage({ id: page.id }));
  };

  const duplicatePage = () => {
    closePopup();
    appDispatch(
      pagesActions.addPage({ id: nanoid(8), pageType: page.pageType, title: page.title, folderId: page.folderId })
    );
  };

  const closePopup = () => {
    setShowPageOptions(false);
  };

  const closeRenamePopup = () => {
    setShowRenamePopup(false);
  };

  return {
    showPageOptions,
    onPageOptionsClick,
    showRenamePopup,
    startPageRename,
    changePageTitle,
    deletePage,
    duplicatePage,
    closePopup,
    closeRenamePopup,
  };
};
