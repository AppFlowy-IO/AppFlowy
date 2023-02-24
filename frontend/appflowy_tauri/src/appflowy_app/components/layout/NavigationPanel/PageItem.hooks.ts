import { IPage, pagesActions } from '../../../stores/reducers/pages/slice';
import { useAppDispatch } from '../../../stores/store';
import { useState } from 'react';
import { nanoid } from 'nanoid';
import { ViewBackendService } from '../../../stores/effects/folder/view/backend_service';

export const usePageEvents = (page: IPage) => {
  const appDispatch = useAppDispatch();
  const [showPageOptions, setShowPageOptions] = useState(false);
  const [showRenamePopup, setShowRenamePopup] = useState(false);
  const viewBackendService: ViewBackendService = new ViewBackendService(page.id);

  const onPageOptionsClick = () => {
    setShowPageOptions(!showPageOptions);
  };

  const startPageRename = () => {
    setShowRenamePopup(true);
    closePopup();
  };

  const changePageTitle = async (newTitle: string) => {
    await viewBackendService.update({ name: newTitle });
    appDispatch(pagesActions.renamePage({ id: page.id, newTitle }));
  };

  const deletePage = async () => {
    closePopup();
    await viewBackendService.delete();
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
